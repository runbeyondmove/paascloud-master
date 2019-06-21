# 用户注册
- github 开源项目–`paascloud-master`：https://github.com/paascloud/paascloud-master
- 分布式解决方案–`基于可靠消息的最终一致性`：https://github.com/paascloud/paascloud-master/wiki/可靠消息

> 本篇文章目的是理解该项目可靠消息服务中心(TCP)发送消息、消费消息的流程，用户注册发送激活邮箱和激活后发送注册成功邮箱都是利用可靠消息服务来解决分布式事务，理解了该流程也就弄懂了该项目中其他业务流程。
> 不明白的请参考文章[微服务架构下的分布式事务解决方案.md](微服务架构下的分布式事务解决方案.md)中的基于可靠消息服务的分布式事务和最大努力通知。

## 发送激活邮箱过程
- 消息生产端：`UAC`
- 可靠消息服务：`TPC`
- 消息服务端：`OPC`
> 用户注册后，向注册邮箱发送一封激活邮箱。

### 消息生产端（UAC）
大致流程为：

1. 本地服务 `UAC` 先持久化 `预发送消息`（等待确认消息），表`pc_mq_message_data`；
1. 调用远端可靠消息服务`TPC`持久化`预发送消息`，可靠消息表`pc_tpc_mq_message`；
1. 执行本地事务即 `保存用户信息` ；
1. 调用远端可靠消息服务`TPC`更新第2步中的`等待确认`状态为`发送中sending`；
1. 同时创建消费待确认列表，即持久化该`Topic`类型的消息被哪些消费者订阅监听的所有消费待确认列表，状态为`未确认`，表`pc_tpc_mq_confirm`；
1. 完成上面操作后，发送消息到 `RocketMQ`。

#### controller层
- AuthRestController.java
```java
@PostMapping(value = "/register")
@ApiOperation(httpMethod = "POST", value = "注册用户")
public Wrapper registerUser(UserRegisterDto user) {
    uacUserService.register(user);
    return WrapMapper.ok();
}
```

#### service层
1. 用户ID生成：`雪花算法生成分布式唯一 ID`
1. 用户密码加密：`SpringSecurity BCryptPasswordEncoder` 强哈希方法加密，每次加密的结果都不一样。

> bcrypt 可以有效抵御彩虹表暴力破解，其原理就是在加盐的基础上多次 hash，关于密码参考：https://mp.weixin.qq.com/s/DkHlZs1HgZmGC9r7WaEDeQ

3. Redis存储激活邮箱token：`key(active_token):email:过期时间1天`，即激活接口参数：`activeUserToken`；
1. 生成邮件发送模板（freeMarker)：`activeUserTemplate.ftl`
1. 根据上面模板和发送邮件参数生成实体：`MqMessageData（pc_mq_message_data）`
> 各个子系统消息落地的消息表，比如用户服务系统主要就是邮件消息、短信消息等。

```java
@Override
public void register(UserRegisterDto registerDto) {
    // 校验注册信息
    validateRegisterInfo(registerDto);
    String mobileNo = registerDto.getMobileNo();
    String email = registerDto.getEmail();
    Date row = new Date();
    String salt = String.valueOf(generateId());
    // 封装注册信息
    long id = generateId();	// id 雪花算法生成
    UacUser uacUser = new UacUser();
    uacUser.setLoginName(registerDto.getLoginName());
    uacUser.setSalt(salt);
    uacUser.setLoginPwd(Md5Util.encrypt(registerDto.getLoginPwd()));
    uacUser.setMobileNo(mobileNo);
    uacUser.setStatus(UacUserStatusEnum.DISABLE.getKey());
    uacUser.setUserSource(UacUserSourceEnum.REGISTER.getKey());
    uacUser.setCreatedTime(row);
    uacUser.setUpdateTime(row);
    uacUser.setEmail(email);
    uacUser.setId(id);
    uacUser.setCreatorId(id);
    uacUser.setCreator(registerDto.getLoginName());
    uacUser.setLastOperatorId(id);
    uacUser.setUserName(registerDto.getLoginName());
    uacUser.setLastOperator(registerDto.getLoginName());

    // 发送激活邮件
    String activeToken = PubUtils.uuid() + super.generateId();
    redisService.setKey(RedisKeyUtil.getActiveUserKey(activeToken), email, 1, TimeUnit.DAYS);

    Map<String, Object> param = Maps.newHashMap();
    param.put("loginName", registerDto.getLoginName());
    param.put("email", registerDto.getEmail());
    param.put("activeUserUrl", activeUserUrl + activeToken);
    param.put("dateTime", DateUtil.formatDateTime(new Date()));

    Set<String> to = Sets.newHashSet();
    to.add(registerDto.getEmail());

    MqMessageData mqMessageData = emailProducer.sendEmailMq(to, UacEmailTemplateEnum.ACTIVE_USER, AliyunMqTopicConstants.MqTagEnum.ACTIVE_USER, param);
    // 即下面的第6步
    userManager.register(mqMessageData, uacUser);
}
```
6. `userManager.register()` 通过注解 `@MqProducerStore` 发送消息服务。

> 执行该方法前，先进入切面编程
```java
@MqProducerStore
public void register(final MqMessageData mqMessageData, final UacUser uacUser) {
    log.info("注册用户. mqMessageData={}, user={}", mqMessageData, uacUser);
    uacUserMapper.insertSelective(uacUser);
}
```

```java
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Inherited
@Documented
public @interface MqProducerStore {
    // WAIT_CONFIRM：等待确认；SAVE_AND_SEND：直接发送；
	MqSendTypeEnum sendType() default MqSendTypeEnum.WAIT_CONFIRM;
    // ORDER(1)：有序；DIS_ORDER(0)：无序
	MqOrderTypeEnum orderType() default MqOrderTypeEnum.ORDER;
    // Rocketmq 默认延时级别
    // ZERO(0, 不延时)；ONE(1, 1秒)....EIGHTEEN(18, 2小时)
	DelayLevelEnum delayLevel() default DelayLevelEnum.ZERO;
}
```

7. 切面中，因为邮件激活发送消息类型为默认的：`等待确认`。
- 此处本地服务 `UAC` 消息落地：保存待确认消息 MqMessageData 到 `mysql`中的本地消息表`pc_mq_message_data`；
- 发送待确认消息到可靠消息系统（TPC）：发送`预发送状态`的消息给消息中心
```java
// 切面
MqMessageData domain = null;
for (Object object : args) {
    if (object instanceof MqMessageData) {
        domain = (MqMessageData) object;
        break;
    }
}
domain.setOrderType(orderType);
domain.setProducerGroup(producerGroup);
// 1. 等待确认
if (type == MqSendTypeEnum.WAIT_CONFIRM) {
    if (delayLevelEnum != DelayLevelEnum.ZERO) {
        domain.setDelayLevel(delayLevelEnum.delayLevel());
    }
    // 1.1 发送待确认消息到可靠消息系统
    // 本地服务消息落地(默认为未发送)，可靠消息服务中心也持久化预发送消息，但是不发送
    mqMessageService.saveWaitConfirmMessage(domain);
}
result = joinPoint.proceed();	// 返回注解方法，执行业务
```

```java
@Override
@Transactional(rollbackFor = Exception.class)
public void saveWaitConfirmMessage(final MqMessageData mqMessageData) {
    // 1. 持久化到本地mysql
    this.saveMqProducerMessage(mqMessageData);
    // 2. 发送预发送状态的消息给消息中心
    TpcMqMessageDto tpcMqMessageDto = mqMessageData.getTpcMqMessageDto();
    // 3. 调用远端可靠消息服务（tpc），持久化等待确认消息
    tpcMqMessageFeignApi.saveMessageWaitingConfirm(tpcMqMessageDto);
    // 4. mqMessageData 此时为调用远端服务返回来的数据
    log.info("<== saveWaitConfirmMessage - 存储预发送消息成功. messageKey={}", mqMessageData.getMessageKey());
}
```

8. 紧接着第7步，调用远端可靠消息服务（TCP），此时只是持久化预发送消息，但是没有发送（等执行完本地事务即保存用户后在发送，即第9步）

> 持久化 `TpcMqMessage`，即 `pc_tpc_mq_message`（可靠消息表）
```java
@Override
public void saveMessageWaitingConfirm(TpcMqMessageDto messageDto) {

    if (StringUtils.isEmpty(messageDto.getMessageTopic())) {
        throw new TpcBizException(ErrorCodeEnum.TPC10050001);
    }

    Date now = new Date();
    TpcMqMessage message = new ModelMapper().map(messageDto, TpcMqMessage.class);
    // 消息状态：WAIT_SEND(10, "未发送")；SENDING(20, "已发送")；FINISH(30, "已完成");
    message.setMessageStatus(MqSendStatusEnum.WAIT_SEND.sendStatus());
    message.setUpdateTime(now);
    message.setCreatedTime(now);
    tpcMqMessageMapper.insertSelective(message);
}
```
> 如果调用远程可靠消息服务出错呢（如网络抖动等），远程调用不成功，事务回滚。此时本地消息表上不存在此消息，以及本地任务还未执行。保证了本地任务和MQ发送的最终一致性。
> 此种情况是没有考虑服务降级的情况，如果要考虑服务降级的情况，要自己实现。  
> 比如对远程调用的结果做判断
> 如果调用远程可靠消息服务出错呢（如网络抖动等），会走断路器，调用还是当作成功的，只是远程可靠消息服务没有持久化这个等待确认状态的消息
> 还是会当作持久化成功，流程还是继续走，直到事务成功。事务成功，此时本地消息表上存在此消息，以及本地任务已经执行。
> 所以这个uac服务应该提供定期任务，定期扫描本地消息表，重新发送消息给远程可靠消息服务，保证本地任务和MQ发送的最终一致性。

9. 上面执行完后，返回注解 `@MqProducerStore`所在方法，执行本地事务：保存用户到 mysql。
```java
result = joinPoint.proceed();	// 返回注解方法，执行业务
```

10. 第9步执行完后，再次进入切面，发送确认消息给可靠消息服务中心
```java
result = joinPoint.proceed();	// 返回注解方法，执行业务
// 2. 直接发送
if (type == MqSendTypeEnum.SAVE_AND_SEND) {
    mqMessageService.saveAndSendMessage(domain);
// 3. XXX
} else if (type == MqSendTypeEnum.DIRECT_SEND) {
    mqMessageService.directSendMessage(domain);
} else {	// type = WAIT_CONFIRM
    final MqMessageData finalDomain = domain;
    taskExecutor.execute(() -> mqMessageService.confirmAndSendMessage(finalDomain.getMessageKey()));
}
return result;
```
> - 疑问1：为什么是使用线程来远程调用可靠消息服务，如果调用出现异常会怎么样？（请查看文章[微服务架构下的分布式事务解决方案](微服务架构下的分布式事务解决方案.md)）
> 异步远程调用，出现异常，不会回滚事务，不影响本地事务的执行

> - 疑问2：这个切面和事务的关系？切面本身也是一个切面

11. 紧接着上面，可靠消息服务中心（TCP）：根据传过来的 `messageKey` 确认并发送之前已经持久化的预发送消息。
```java
// TpcMqMessageFeignClient.java
@Override
@ApiOperation(httpMethod = "POST", value = "确认并发送消息")
public Wrapper confirmAndSendMessage(@RequestParam("messageKey") String messageKey) {
    logger.info("确认并发送消息. messageKey={}", messageKey);
    tpcMqMessageService.confirmAndSendMessage(messageKey);
    return WrapMapper.ok();
}

// TpcMqMessageServiceImpl.java
@Override
public void confirmAndSendMessage(String messageKey) {
    final TpcMqMessage message = tpcMqMessageMapper.getByMessageKey(messageKey);
    if (message == null) {
        throw new TpcBizException(ErrorCodeEnum.TPC10050002);
    }

    TpcMqMessage update = new TpcMqMessage();
    update.setMessageStatus(MqSendStatusEnum.SENDING.sendStatus());
    update.setId(message.getId());
    update.setUpdateTime(new Date());
    // 1. 更新消息状态为：SENDING
    tpcMqMessageMapper.updateByPrimaryKeySelective(update);
    // 2. 创建消费待确认列表（此处topic：SEND_EMAIL_TOPIC）
    this.createMqConfirmListByTopic(message.getMessageTopic(), message.getId(), message.getMessageKey());
    // 3. 直接发送消息
    this.directSendMessage(message.getMessageBody(), message.getMessageTopic(),
     message.getMessageTag(), message.getMessageKey(), message.getProducerGroup(), message.getDelayLevel());
}
```

12. 第11步中的第2点：`TCP` 服务中，创建消费待确认列表，根据表 `pc_tpc_mq_subscribe`，查询出不同 `topic` 下相对应的所有 `consumer_code`（消费监听者），即设置该消息被哪些服务（CID）监听消费；
 图片：post_1_pc_tpc_mq_subcribe.jpg
 
- `SEND_EMAIL_TOPIC` --> `CID_OPC`：该消息会被 `consumerGroup` 为 `CID_OPC` 的服务监听并消费。
- 同时，保存确认消息：`TpcMqConfirm` --> 表 `pc_tpc_mq_confirm`

```java
@Override
public void createMqConfirmListByTopic(final String topic, final Long messageId, final String messageKey) {
    List<TpcMqConfirm> list = Lists.newArrayList();
    TpcMqConfirm tpcMqConfirm;
    List<String> consumerGroupList = tpcMqConsumerService.listConsumerGroupByTopic(topic);
    if (PublicUtil.isEmpty(consumerGroupList)) {
        throw new TpcBizException(ErrorCodeEnum.TPC100500010, topic);
    }
    for (final String cid : consumerGroupList) {
        tpcMqConfirm = new TpcMqConfirm(UniqueIdGenerator.generateId(), messageId, messageKey, cid);
        list.add(tpcMqConfirm);
    }

    tpcMqConfirmMapper.batchCreateMqConfirm(list);
}
```
13. 第11步中的第3点：完成上面操作后，直接发送消息到中间件 `RocketMQ` 队列中。
```java
@Override
public void directSendMessage(String body, String topic, String tag, String key,
        String pid, Integer delayLevel) {
    RocketMqProducer.sendSimpleMessage(body, topic, tag, key, pid, delayLevel);
}

// 核心方法：重试发送消息（重试次数3次）
// pid：producerGroup --> 发送邮件服务是 PID_UAC
// cid: consumerGroup --> 监听邮件消息服务是 CID_OPC
private static SendResult retrySendMessage(String pid, Message msg) {
    int iniCount = 1;
    SendResult result;
    while (true) {
        try {
            // Message中属性
            result = MqProducerBeanFactory.getBean(pid).send(msg);
            break;
        } catch (Exception e) {
            log.error("发送消息失败:", e);
            if (iniCount++ >= PRODUCER_RETRY_TIMES) {
                throw new TpcBizException(ErrorCodeEnum.TPC100500014, msg.getTopic(), msg.getKeys());
            }
        }
    }
    log.info("<== 发送MQ SendResult={}", result);
    return result;
}
```

### 消息消费端（OPC）
#### 大致流程：

1. OPC服务通过配置类`AliyunMqConfiguration.java`启动`DefaultMQPushConsumer` RocketMQ 消费端，并设置消息逻辑处理监听器`OptPushMessageListener`；
1. 本地服务`OPC`持久化消费者确认消息，表 `pc_mq_message_data`；
1. 调用远端可靠消息服务`TPC`，更新之前生产端持久化的消费确认列表状态，`未确认` --> `已确认`，表`pc_tpc_mq_confirm`；
1. 接着就可以发送激活邮箱；
1. 如果发送成功，调用远端可靠消息服务`TPC`，继续更新第3步表中消费确认消息的状态为`已消费`；

#### 消费端 RocketMQ 启动配置类
1. `DefaultMQPushConsumer` 根据配置信息启动；
1. 并 `subscribe` 订阅 该服务 `OPC` 所有的 `Topic` 和 `tags` 消息。
> 包括短信、邮箱激活、附件更新删除等所有消息。
```java
@Slf4j
@Configuration
public class AliyunMqConfiguration {

	@Resource
	private PaascloudProperties paascloudProperties;

	@Resource
	private OptPushMessageListener optPushConsumer;

	@Resource
	private TaskExecutor taskExecutor;

	/**
	 * Default mq push consumer default mq push consumer.
	 *
	 * @return the default mq push consumer
	 *
	 * @throws MQClientException the mq client exception
	 */
	@Bean
	public DefaultMQPushConsumer defaultMQPushConsumer() throws MQClientException {
		// 1. 新建消费者组
		// RocketMQ实际上都是拉模式，这里的DefaultMQPushConsumer实现了推模式，
		// 也只是对拉消息服务做了一层封装，即拉到消息的时候触发业务消费者注册到这里的callback
		DefaultMQPushConsumer consumer = new DefaultMQPushConsumer(paascloudProperties.getAliyun().getRocketMq().getConsumerGroup());
		// 2. 指定NameServer地址，多个地址以 ; 隔开
		consumer.setNamesrvAddr(paascloudProperties.getAliyun().getRocketMq().getNamesrvAddr());
		// 3. 设置Consumer第一次启动是从队列头部开始消费还是队列尾部开始消费
		// 如果非第一次启动，那么按照上次消费的位置继续消费
		consumer.setConsumeFromWhere(ConsumeFromWhere.CONSUME_FROM_LAST_OFFSET);

		String[] strArray = AliyunMqTopicConstants.ConsumerTopics.OPT.split(GlobalConstant.Symbol.COMMA);
		for (String aStrArray : strArray) {
			String[] topicArray = aStrArray.split(GlobalConstant.Symbol.AT);
			String topic = topicArray[0];
			String tags = topicArray[1];
			if (PublicUtil.isEmpty(tags)) {
				tags = "*";
			}
			// 4. 进行Topic订阅，订阅PushTopic下Tag为push的消息
			consumer.subscribe(topic, tags);
			log.info("RocketMq OpcPushConsumer topic = {}, tags={}", topic, tags);
		}

		// 5. 设置消息处理器
		consumer.registerMessageListener(optPushConsumer);
		consumer.setConsumeThreadMax(2);
		consumer.setConsumeThreadMin(2);

		taskExecutor.execute(() -> {
			try {
				Thread.sleep(5000);
				consumer.start();
				log.info("RocketMq OpcPushConsumer OK.");
			} catch (InterruptedException | MQClientException e) {
				log.error("RocketMq OpcPushConsumer, 出现异常={}", e.getMessage(), e);
			}
		});
		return consumer;
	}
}
```


#### 消息逻辑处理监听器
1. `consumeMessage()` 上有注解 `@MqConsumerStore`，执行前先进入切面编程；
```java
@Slf4j
@Component
public class OptPushMessageListener implements MessageListenerConcurrently {

	@Resource
	private OptSendSmsTopicConsumer optSendSmsTopicService;
	@Resource
	private OptSendEmailTopicConsumer optSendEmailTopicService;
	@Resource
	private MdcTopicConsumer mdcTopicConsumer;

	@Resource
	private MqMessageService mqMessageService;
	@Resource
	private StringRedisTemplate srt;

	/**
	 * Consume message consume concurrently status.
	 *
	 * @param messageExtList             the message ext list
	 * @param consumeConcurrentlyContext the consume concurrently context
	 *
	 * @return the consume concurrently status
	 */
	@Override
	@MqConsumerStore
	public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> messageExtList, ConsumeConcurrentlyContext consumeConcurrentlyContext) {
		MessageExt msg = messageExtList.get(0);
		String body = new String(msg.getBody());
		String topicName = msg.getTopic();
		String tags = msg.getTags();
		String keys = msg.getKeys();
		log.info("MQ消费Topic={},tag={},key={}", topicName, tags, keys);
		ValueOperations<String, String> ops = srt.opsForValue();
		// 控制幂等性使用的key
		try {
			MqMessage.checkMessage(body, topicName, tags, keys);
			String mqKV = null;
			if (srt.hasKey(keys)) {
				mqKV = ops.get(keys);
			}
			if (PublicUtil.isNotEmpty(mqKV)) {
				log.error("MQ消费Topic={},tag={},key={}, 重复消费", topicName, tags, keys);

				// 消费成功
				return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
			}
			if (AliyunMqTopicConstants.MqTopicEnum.SEND_SMS_TOPIC.getTopic().equals(topicName)) {
				optSendSmsTopicService.handlerSendSmsTopic(body, topicName, tags, keys);
			}
			if (AliyunMqTopicConstants.MqTopicEnum.SEND_EMAIL_TOPIC.getTopic().equals(topicName)) {
				optSendEmailTopicService.handlerSendEmailTopic(body, topicName, tags, keys);
			}
			if (AliyunMqTopicConstants.MqTopicEnum.TPC_TOPIC.getTopic().equals(topicName)) {
				mqMessageService.deleteMessageTopic(body, tags);
			}
			if (AliyunMqTopicConstants.MqTopicEnum.MDC_TOPIC.getTopic().equals(topicName)) {
				mdcTopicConsumer.handlerSendSmsTopic(body, topicName, tags, keys);
			} else {
				log.info("OPC订单信息消 topicName={} 不存在", topicName);
			}
		} catch (IllegalArgumentException ex) {
			log.error("校验MQ message 失败 ex={}", ex.getMessage(), ex);
		} catch (Exception e) {
			log.error("处理MQ message 失败 topicName={}, keys={}, ex={}", topicName, keys, e.getMessage(), e);
			// 如果消息消费失败，例如数据库异常等，扣款失败，发送失败需要重试的场景，
			// 返回下面代码，RocketMQ就认为消费失败。
			return ConsumeConcurrentlyStatus.RECONSUME_LATER;
		}
		ops.set(keys, keys, 10, TimeUnit.DAYS);
		// 业务实现消费回调的时候，当且仅当返回下面代码时，RocketMQ才会认为这批消息是消费完成的
		return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
	}
}
```
2. 执行方法之前先进入切面编程执行，获取注解方法的参数和消息；
```java
@Around(value = "mqConsumerStoreAnnotationPointcut()")
public Object processMqConsumerStoreJoinPoint(ProceedingJoinPoint joinPoint) throws Throwable {
    // ...
    MqMessageData dto = this.getTpcMqMessageDto(messageExtList.get(0));
    final String messageKey = dto.getMessageKey();
    if (isStorePreStatus) {
        // 执行下面3、4步
        mqMessageService.confirmReceiveMessage(consumerGroup, dto);
    }
    String methodName = joinPoint.getSignature().getName();
    try {
        // 返回注解方法；
        result = joinPoint.proceed();
        log.info("result={}", result);
        if (CONSUME_SUCCESS.equals(result.toString())) {
            mqMessageService.saveAndConfirmFinishMessage(consumerGroup, messageKey);
        }
    } catch (Exception e) {
        log.error("发送可靠消息, 目标方法[{}], 出现异常={}", methodName, e.getMessage(), e);
        throw e;
    } finally {
        log.info("发送可靠消息 目标方法[{}], 总耗时={}", methodName, System.currentTimeMillis() - startTime);
    }
    return result;
}
```

3. `confirmReceiveMessage`：消费者确认收到消息；在上面目录【发送激活邮箱的消息/service层】的第 12 步
> 持久化消费者确认消息 `MqMessageData` 到本地服务 `OPC` mysql 中，表 `pc_mq_message_data`；

```java
@Override
@Transactional(rollbackFor = Exception.class)
public void confirmReceiveMessage(String cid, MqMessageData messageData) {
    final String messageKey = messageData.getMessageKey();
    log.info("confirmReceiveMessage - 消费者={}, 确认收到key={}的消息", cid, messageKey);
    // 持久化消费者确认消息 MqMessageData 到本地服务 mysql 中，表 pc_mq_message_data
    messageData.setMessageType(MqMessageTypeEnum.CONSUMER_MESSAGE.messageType());
    messageData.setId(UniqueIdGenerator.generateId());
    mqMessageDataMapper.insertSelective(messageData);
    // 调用远端服务 TPC，更新确认收到消息表状态为已确认，TpcMqConfirm，表 pc_tpc_mq_confirm；
    Wrapper wrapper = tpcMqMessageFeignApi.confirmReceiveMessage(cid, messageKey);
    log.info("tpcMqMessageFeignApi.confirmReceiveMessage result={}", wrapper);
    if (wrapper == null) {
        throw new TpcBizException(ErrorCodeEnum.GL99990002);
    }
    if (wrapper.error()) {
        throw new TpcBizException(ErrorCodeEnum.TPC10050004, wrapper.getMessage(), messageKey);
    }
}
```

4. 紧接着第3步，调用远端服务 `TPC`，更新确认收到消息状态为已确认，`TpcMqConfirm`，表 `pc_tpc_mq_confirm`；
- status：状态, 10 - 未确认 ; 20 - 已确认; 30 已消费；
- consumeCount：消费的次数，加 1；
```java
@Override
public void confirmReceiveMessage(final String cid, final String messageKey) {
    // 1. 校验cid
    // 2. 校验messageKey
    // 3. 校验cid 和 messageKey
    Long confirmId = tpcMqConfirmMapper.getIdMqConfirm(cid, messageKey);
    // 3. 更新消费信息的状态
    tpcMqConfirmMapper.confirmReceiveMessage(confirmId);
}
```
5. 第3、4步执行后，返回切面，执行下面代码，再返回注解修饰的方法；
```java
result = joinPoint.proceed();
```

6. 注解修饰方法，通过参数 `MessageExt` 获取该消息的 `topic（主题）`、`tag（标签）`、`keys（唯一键）`、`body（消息体）`；

7. 幂等性（避免重复消费）：`redis` 中存储消费过的该消息的 `keys`；

8. 根据消息的 `topic` 执行相应的操作处理该消息

> 比如此流程的发送激活邮箱，使用 spring 框架的 `TaskExecutor`执行邮箱发送任务。
```java
@Override
public int sendSimpleMail(String subject, String text, Set<String> to) {
    log.info("sendSimpleMail - 发送简单邮件. subject={}, text={}, to={}", subject, text, to);
    int result = 1;
    try {
        SimpleMailMessage message = MailEntity.createSimpleMailMessage(subject, text, to);
        message.setFrom(from);
        taskExecutor.execute(() -> mailSender.send(message));
    } catch (Exception e) {
        log.info("sendSimpleMail [FAIL] ex={}", e.getMessage(), e);
        result = 0;
    }
    return result;
}
```

9. `第8步` 如果消息消费成功，邮件发送成功，`redis` 中存储该消息（幂等，过期时间 10 天），同时返回消费成功代码；
```java
ops.set(keys, keys, 10, TimeUnit.DAYS);
// 业务实现消费回调的时候，当且仅当返回下面代码时，RocketMQ 才会认为这批消息是消费完成的
return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
```

10. `第8步` 如果消息消费失败，比如数据库异常，扣款失败，邮件发送失败等需要重试的场景，返回重试消费代码。
```java
} catch (IllegalArgumentException ex) {
    log.error("校验MQ message 失败 ex={}", ex.getMessage(), ex);
} catch (Exception e) {
    log.error("处理MQ message 失败 topicName={}, keys={}, ex={}", topicName, keys, e.getMessage(), e);
    // 如果消息消费失败，例如数据库异常等，扣款失败，发送失败需要重试的场景，
    // 返回下面代码，RocketMQ就认为消费失败。
    return ConsumeConcurrentlyStatus.RECONSUME_LATER;
}
```

11. 执行完注解修饰方法，再次返回切面中，继续执行，判断返回结果；
```java
String methodName = joinPoint.getSignature().getName();
try {
    result = joinPoint.proceed();
    log.info("result={}", result);
    if (CONSUME_SUCCESS.equals(result.toString())) {
        mqMessageService.saveAndConfirmFinishMessage(consumerGroup, messageKey);
    }
} catch (Exception e) {
    log.error("发送可靠消息, 目标方法[{}], 出现异常={}", methodName, e.getMessage(), e);
    throw e;
} finally {
    log.info("发送可靠消息 目标方法[{}], 总耗时={}", methodName, System.currentTimeMillis() - startTime);
}
return result;
```
12. 第11步中，如果返回 `CONSUME_SUCCESS`，保存并确认消息完成；
- 调用远端服务 `TCP`，更新消费确认消息列表 `pc_tpc_mq_confirm`，状态为`已消费`；
```java
@Override
public void saveAndConfirmFinishMessage(String cid, String messageKey) {
    // 1. 调用远端服务tcp，确认完成消费消息
    Wrapper wrapper = tpcMqMessageFeignApi.confirmConsumedMessage(cid, messageKey);
    log.info("tpcMqMessageFeignApi.confirmReceiveMessage result={}", wrapper);
    if (wrapper == null) {
        throw new TpcBizException(ErrorCodeEnum.GL99990002);
    }
    if (wrapper.error()) {
        throw new TpcBizException(ErrorCodeEnum.TPC10050004, wrapper.getMessage(), messageKey);
    }
}
```

## 发送激活成功邮箱过程
> 发送激活成功邮箱同上面发送激活邮箱一样利用可靠消息服务完成分布式事务操作。

### controller层
```java
@GetMapping(value = "/activeUser/{activeUserToken}")
@ApiOperation(httpMethod = "POST", value = "激活用户")
public Wrapper activeUser(@PathVariable String activeUserToken) {
    uacUserService.activeUser(activeUserToken);
    return WrapMapper.ok("激活成功");
}
```
### service 层
1. activeuser()
```java
@Override
public void activeUser(String activeUserToken) {
	Preconditions.checkArgument(!StringUtils.isEmpty(activeUserToken), "激活用户失败");

	String activeUserKey = RedisKeyUtil.getActiveUserKey(activeUserToken);

	String email = redisService.getKey(activeUserKey);

	if (StringUtils.isEmpty(email)) {
		throw new UacBizException(ErrorCodeEnum.UAC10011030);
	}
	// 修改用户状态, 绑定访客角色
	UacUser uacUser = new UacUser();
	uacUser.setEmail(email);

	uacUser = uacUserMapper.selectOne(uacUser);
	if (uacUser == null) {
		logger.error("找不到用户信息. email={}", email);
		throw new UacBizException(ErrorCodeEnum.UAC10011004, email);
	}

	UacUser update = new UacUser();
	update.setId(uacUser.getId());
	update.setStatus(UacUserStatusEnum.ENABLE.getKey());
	LoginAuthDto loginAuthDto = new LoginAuthDto();
	loginAuthDto.setUserId(uacUser.getId());
	loginAuthDto.setUserName(uacUser.getLoginName());
	loginAuthDto.setLoginName(uacUser.getLoginName());
	update.setUpdateInfo(loginAuthDto);

	UacUser user = this.queryByUserId(uacUser.getId());

	Map<String, Object> param = Maps.newHashMap();
	param.put("loginName", user.getLoginName());
	param.put("dateTime", DateUtil.formatDateTime(new Date()));

	Set<String> to = Sets.newHashSet();
	to.add(user.getEmail());

	// 构建激活成功消息体
	MqMessageData mqMessageData = emailProducer.sendEmailMq(to, UacEmailTemplateEnum.ACTIVE_USER_SUCCESS, AliyunMqTopicConstants.MqTagEnum.ACTIVE_USER_SUCCESS, param);
	// 1. 可靠消息服务发送邮件
	userManager.activeUser(mqMessageData, update, activeUserKey);
}
```
2. 调用`userManager.activeUser()`：可以看到该方法也是注解`@MqProducerStore`修饰；
```java
@MqProducerStore
public void activeUser(final MqMessageData mqMessageData, final UacUser uacUser, final String activeUserKey) {
	log.info("激活用户. mqMessageData={}, user={}", mqMessageData, uacUser);
	// 更新用户信息
	int result = uacUserMapper.updateByPrimaryKeySelective(uacUser);
	if (result < 1) {
		throw new UacBizException(ErrorCodeEnum.UAC10011038, uacUser.getId());
	}

	// 绑定一个访客角色默认值roleId=10000
	final Long userId = uacUser.getId();
	Preconditions.checkArgument(userId != null, "用戶Id不能爲空");

	final Long roleId = 10000L;

	UacRoleUser roleUser = new UacRoleUser();
	roleUser.setUserId(userId);
	roleUser.setRoleId(roleId);
	uacRoleUserMapper.insertSelective(roleUser);
	// 绑定一个组织
	UacGroupUser groupUser = new UacGroupUser();
	groupUser.setUserId(userId);
	groupUser.setGroupId(GlobalConstant.Sys.SUPER_MANAGER_GROUP_ID);
	uacGroupUserMapper.insertSelective(groupUser);
	// 删除 activeUserToken
	redisService.deleteKey(activeUserKey);
}
```

3. 本地事务执行用户信息更新和 `redis` 邮箱激活token删除，切面编程发送激活成功邮箱分析过程和上面发送激活邮箱流程是一样的，这里不再赘述。

4. 这两个过程根据发送消息的 `tag` 不同，从而处理逻辑不同。`Topic` 都是 `SEND_EMAIL_TOPIC`；

> 此处具体为邮箱内容模板不同，其余消息生产端和消费端流程一样。
```java
public enum MqTagEnum {
	/**
	 * 激活用户.
	 */
	ACTIVE_USER("ACTIVE_USER", MqTopicEnum.SEND_EMAIL_TOPIC.getTopic(), "激活用户"),
	/**
	 * 激活用户成功.
	 */
	ACTIVE_USER_SUCCESS("ACTIVE_USER_SUCCESS", MqTopicEnum.SEND_EMAIL_TOPIC.getTopic(), "激活用户成功"),
	
	// ...省略其他tag
    ;

	String tag;
	String topic;
	String tagName;

	MqTagEnum(String tag, String topic, String tagName) {
		this.tag = tag;
		this.topic = topic;
		this.tagName = tagName;
	}
	
	public String getTag() {
		return tag;
	}
	public String getTopic() {
		return topic;
	}
}
```




