# 1 前言
## 1.1 paascloud-master
- github 开源项目–paascloud-master：https://github.com/paascloud/paascloud-master
- paascloud-master 可靠消息设计文档：https://github.com/paascloud/paascloud-master/wiki/可靠消息
> 文档备份地址：https://blog.csdn.net/liu_zhaoming/article/details/79603036

## 1.2 Elastic-Job
1. [github 开源地址：https://github.com/elasticjob/elastic-job-lite](https://github.com/elasticjob/elastic-job-lite)
1. [官方文档](http://elasticjob.io/docs/elastic-job-lite/00-overview/)
1. [官方开发指南](http://elasticjob.io/docs/elastic-job-lite/01-start/dev-guide/)
1. [github使用项目](https://github.com/xjzrc/elastic-job-lite-spring-boot-starter)
1. [参考博客：Elastic-Job——分布式定时任务框架。](https://www.cnblogs.com/wyb628/p/7682580.html)
1. [参考博客：分布式定时任务Elastic-Job框架在SpringBoot工程中的应用实践（一）](https://www.jianshu.com/p/b91b792f0ac6)

# 2 如何使用
## 2.1 本项目需求
项目里下面 `5种` 情况使用了定时任务 `Elastic-Job`。
> 参考：https://github.com/paascloud/paascloud-master/wiki/可靠消息

1. 定时清理所有**订阅者** 7 天前`消费成功`的消息数据【每天0点】；
1. 定时清理所有**生产者** 7天前 `发送成功`的消息数据【每天1点】；
1. 定时清理无效**OSS文件**（图片）【每天0点】；
1. 处理`发送中`的消息数据【30秒执行一次】；
1. 处理`待确认`的消息数据【10分钟执行一次】；
1. 超时 token 更新为离线，token有效时长2小时【每天0点】；

> 下面我们以第一种情况分析如何使用 `Elastic-Job`的。

## 2.2定时清理消息
任务：**定时清理订阅者消费成功的消息数据。**

1. `DeleteRpcConsumerMessageJob.java`
> 此处的 `SimpleJob` 可以参考文档：http://elasticjob.io/docs/elastic-job-lite/01-start/dev-guide/
```java
/**
 * 定时清理所有订阅者消费成功的消息数据.
 *
 * @author paascloud.net @gmail.com
 */
@Slf4j
@ElasticJobConfig(cron = "0 0 0 1/1 * ?")	// 每天00:00:00
public class DeleteRpcConsumerMessageJob implements SimpleJob {
	@Resource
	private PaascloudProperties paascloudProperties;
	@Resource
	private TpcMqMessageService tpcMqMessageService;

	/**
	 * Execute.
	 *
	 * @param shardingContext the sharding context
	 */
	@Override
	public void execute(final ShardingContext shardingContext) {
		ShardingContextDto shardingContextDto = new ShardingContextDto(shardingContext.getShardingTotalCount(), shardingContext.getShardingItem());
		final TpcMqMessageDto message = new TpcMqMessageDto();
		// 将 Elastic-Job 该定时任务分片上下文设置到消息体中
		message.setMessageBody(JSON.toJSONString(shardingContextDto));
		// 设置清理任务的消息标签：删除消费者历史消息
		message.setMessageTag(AliyunMqTopicConstants.MqTagEnum.DELETE_CONSUMER_MESSAGE.getTag());
		// 设置清理任务的消息主题
		message.setMessageTopic(AliyunMqTopicConstants.MqTopicEnum.TPC_TOPIC.getTopic());
		// 设置该服务的生产组
		message.setProducerGroup(paascloudProperties.getAliyun().getRocketMq().getProducerGroup());
		String refNo = Long.toString(UniqueIdGenerator.generateId());
		message.setRefNo(refNo);
		message.setMessageKey(refNo);
		// 发送清理所有订阅者消费成功的消息数据
		tpcMqMessageService.saveAndSendMessage(message);
	}
}
```

2. 注解 `@ElasticJobConfig(cron = "0 0 0 1/1 * ?")` 设置定时任务相关信息。

> 自定义注解参考博客：https://www.cnblogs.com/liaojie970/p/7879917.html

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Component
public @interface ElasticJobConfig {

	/**
	 * cron表达式，用于控制作业触发时间
	 *
	 * @return String string
	 */
	String cron();

	/**
	 * 作业分片总
	 *
	 * @return int int
	 */
	int shardingTotalCount() default 1;

	/**
	 * 分片序列号和个性化参数对照表.
	 * 分片序列号和参数用等号分隔, 多个键值对用逗号分隔. 类似map.
	 * 分片序列号从0开始, 不可大于或等于作业分片总数.
	 * 如:
	 * 0=a,1=b,2=c
	 *
	 * @return String string
	 */
	String shardingItemParameters() default "";

	/**
	 * 作业自定义参数.
	 * 作业自定义参数，可通过传递该参数为作业调度的业务方法传参，用于实现带参数的作业
	 * 例：每次获取的数据量、作业实例从数据库读取的主键等
	 *
	 * @return String string
	 */
	String jobParameter() default "";

	/**
	 * 是否开启任务执行失效转移，开启表示如果作业在一次任务执行中途宕机，
	 * 允许将该次未完成的任务在另一作业节点上补偿执行
	 *
	 * @return boolean boolean
	 */
	boolean failover() default false;

	/**
	 * 是否开启错过任务重新执行
	 *
	 * @return boolean boolean
	 */
	boolean misfire() default true;

	/** ... **/
}
```

3. 紧接着第1步，监听器监听`topic`消息，从而执行删除业务：`MqMessageServiceImpl.java`
```java
@Override
@Transactional(rollbackFor = Exception.class)
public void deleteMqMessage(final int shardingTotalCount, final int shardingItem, final String tags) {
	// 分页参数每页5000条
	int pageSize = 1000;
	int messageType;
	// 1. 删除所有生产者发送成功的消息数据
	if (AliyunMqTopicConstants.MqTagEnum.DELETE_PRODUCER_MESSAGE.getTag().equals(tags)) {
		messageType = MqMessageTypeEnum.PRODUCER_MESSAGE.messageType();
	// 2. 删除所有订阅者消费成功的消息数据
	} else {
		messageType = MqMessageTypeEnum.CONSUMER_MESSAGE.messageType();
	}

	int totalCount = mqMessageDataMapper.getBefore7DayTotalCount(shardingTotalCount, shardingItem, messageType);
	if (totalCount == 0) {
		return;
	}
	// 分页参数, 总页数
	int pageNum = (totalCount - 1) / pageSize + 1;

	for (int currentPage = 1; currentPage < pageNum; currentPage++) {
		List<Long> idList = mqMessageDataMapper.getIdListBefore7Day(shardingTotalCount, shardingItem, messageType, currentPage, pageSize);
		mqMessageDataMapper.batchDeleteByIdList(idList);
	}
}
```
## 2.3 zk 注册中心数据结构

作业启动后，`zookeeper` 注册中心创建了作业相关数据节点：

图片：post_2_2.3_1.jpg

1. 注册中心在定义的命名空间下，创建作业名称节点 `com.paascloud.elastic.demo.SimpleJobDemo`，用于区分不同作业，所以**作业一旦创建则不能修改作业名称，如果修改名称将视为新的作业。**
2. 作业名称节点下又包含 `5个` 数据子节点，分别是`config`, `instances`, `sharding`, `servers`和`leader`。

> 具体含义参考：http://elasticjob.io/docs/elastic-job-lite/03-design/lite-design/

## 2.4 elastic-job-console 运维平台
> 文章摘要：在生产环境中部署Elastic-Job集群后，那么如何来运维监控线上跑着的定时任务呢？

如果在生产环境的大规模服务器集群上部署了集成`Elastic-Job` 的业务工程，而没有相应的运维监控工具可以来监控定时任务执行状态和动态修改定时任务执行时间，
修改相应的配置还得手动更新数据库或者配置文件，那么则会给运维和研发工程师增添不少麻烦。
使用过 `Quartz` 集群方案的同学应该都有过同样的感触，修改定时任务执行时间配置和监控任务的状态都比较麻烦，想要一个功能齐全的监控运维平台还得自己专门来开发。所幸的是，`Elastic-Job` 开源社区很早就考虑到该问题，
在项目发布初期即提供了一个功能相对齐全的`Elastic-Job` 运维监控 `console` 平台。

- 参考博客：https://www.jianshu.com/p/5a66e69b10d5
- 官方文档：http://elasticjob.io/docs/elastic-job-lite/02-guide/web-console/