/*
 * Copyright (c) 2018. paascloud.net All Rights Reserved.
 * 项目名称：paascloud快速搭建企业级分布式微服务平台
 * 类名称：MqProducerStoreAspect.java
 * 创建人：刘兆明
 * 联系方式：paascloud.net@gmail.com
 * 开源地址: https://github.com/paascloud
 * 博客地址: http://blog.paascloud.net
 * 项目官网: http://paascloud.net
 */

package com.paascloud.provider.aspect;

import com.paascloud.base.enums.ErrorCodeEnum;
import com.paascloud.provider.annotation.MqProducerStore;
import com.paascloud.provider.exceptions.TpcBizException;
import com.paascloud.provider.model.domain.MqMessageData;
import com.paascloud.provider.model.enums.DelayLevelEnum;
import com.paascloud.provider.model.enums.MqSendTypeEnum;
import com.paascloud.provider.service.MqMessageService;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.task.TaskExecutor;

import javax.annotation.Resource;
import java.lang.reflect.Method;


/**
 * The class Mq producer store aspect.
 *
 * @author paascloud.net @gmail.com
 */
@Slf4j
@Aspect
public class MqProducerStoreAspect {
	@Resource
	private MqMessageService mqMessageService;

	@Value("${paascloud.aliyun.rocketMq.producerGroup}")
	private String producerGroup;

	@Resource
	private TaskExecutor taskExecutor;

	/**
	 * Add exe time annotation pointcut.
	 */
	@Pointcut("@annotation(com.paascloud.provider.annotation.MqProducerStore)")
	public void mqProducerStoreAnnotationPointcut() {

	}

	/**
	 * 一个topic对应一个生产者，而可靠消息采用的是中间件负责发送消息
	 *
	 * 上游应用将本地业务执行和消息发送绑定在同一个本地事务中，保证要么本地操作成功并发送 MQ 消息，要么两步操作都失败并回滚。这里采用自定义切面完成，可对照代码查看。
	 * 1. 上游应用发送待确认消息到可靠消息系统。(本地消息落地)
	 * 2. 可靠消息系统保存待确认消息并返回。
	 * 3. 上游应用执行本地业务。
	 * 4. 上游应用通知可靠消息系统确认业务已执行并发送消息。
	 * 5. 可靠消息系统修改消息状态为发送状态并将消息投递到 MQ 中间件。
	 *
	 *  消息发送一致性：是指产生消息的业务动作与消息发送的一致。
	 *  也就是说，如果业务操作成功，那么由这个业务操作所产生的消息一定要成功投递出去(一般是发送到kafka、rocketmq、rabbitmq等消息中间件中)，否则就丢消息。
	 *  再简单点就是使用@MqProducerStore的方法必须配合@Transactional注解使用
	 *
	 * 参考文章：http://www.tianshouzhi.com/api/tutorials/distributed_transaction/389
	 * 或者http://blog.paascloud.net/2018/03/18/java-env/rocketmq/rocketmq-reliable-message-consistency/
	 */
	/**
	 * Add exe time method object.
	 *
	 * @param joinPoint the join point
	 *
	 * @return the object
	 */
	@Around(value = "mqProducerStoreAnnotationPointcut()")
	public Object processMqProducerStoreJoinPoint(ProceedingJoinPoint joinPoint) throws Throwable {
		log.info("processMqProducerStoreJoinPoint - 线程id={}", Thread.currentThread().getId());
		Object result;
		Object[] args = joinPoint.getArgs();
		MqProducerStore annotation = getAnnotation(joinPoint);
		MqSendTypeEnum type = annotation.sendType();
		int orderType = annotation.orderType().orderType();
		DelayLevelEnum delayLevelEnum = annotation.delayLevel();
		if (args.length == 0) {
			throw new TpcBizException(ErrorCodeEnum.TPC10050005);
		}
		MqMessageData domain = null;
		for (Object object : args) {
			if (object instanceof MqMessageData) {
				domain = (MqMessageData) object;
				break;
			}
		}

		if (domain == null) {
			throw new TpcBizException(ErrorCodeEnum.TPC10050005);
		}

		domain.setOrderType(orderType);
		domain.setProducerGroup(producerGroup);
		if (type == MqSendTypeEnum.WAIT_CONFIRM) {
			if (delayLevelEnum != DelayLevelEnum.ZERO) {
				domain.setDelayLevel(delayLevelEnum.delayLevel());
			}
			mqMessageService.saveWaitConfirmMessage(domain);
		}
		result = joinPoint.proceed();

		// 经过测试，发现下面如果出现异常，则事务都回滚掉
		if (type == MqSendTypeEnum.SAVE_AND_SEND) {
			mqMessageService.saveAndSendMessage(domain);
		} else if (type == MqSendTypeEnum.DIRECT_SEND) {
			mqMessageService.directSendMessage(domain);
		} else {
			final MqMessageData finalDomain = domain;
			taskExecutor.execute(() -> mqMessageService.confirmAndSendMessage(finalDomain.getMessageKey()));
		}
		return result;
	}

	private static MqProducerStore getAnnotation(JoinPoint joinPoint) {
		MethodSignature methodSignature = (MethodSignature) joinPoint.getSignature();
		Method method = methodSignature.getMethod();
		return method.getAnnotation(MqProducerStore.class);
	}
}
