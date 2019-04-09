/*
 * Copyright (c) 2018. paascloud.net All Rights Reserved.
 * 项目名称：paascloud快速搭建企业级分布式微服务平台
 * 类名称：AliyunMqConfiguration.java
 * 创建人：刘兆明
 * 联系方式：paascloud.net@gmail.com
 * 开源地址: https://github.com/paascloud
 * 博客地址: http://blog.paascloud.net
 * 项目官网: http://paascloud.net
 */

package com.paascloud.provider.config;

import com.paascloud.PublicUtil;
import com.paascloud.base.constant.AliyunMqTopicConstants;
import com.paascloud.base.constant.GlobalConstant;
import com.paascloud.config.properties.PaascloudProperties;
import com.paascloud.provider.consumer.listener.OptPushMessageListener;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.client.consumer.DefaultMQPushConsumer;
import org.apache.rocketmq.client.exception.MQClientException;
import org.apache.rocketmq.common.consumer.ConsumeFromWhere;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.TaskExecutor;

import javax.annotation.Resource;

/**
 * The class Aliyun mq configuration.
 *
 * @author paascloud.net@gmail.com
 */
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
