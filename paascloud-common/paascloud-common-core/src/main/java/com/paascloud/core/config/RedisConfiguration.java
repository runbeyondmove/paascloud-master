/*
 * Copyright (c) 2018. paascloud.net All Rights Reserved.
 * 项目名称：paascloud快速搭建企业级分布式微服务平台
 * 类名称：RedisConfiguration.java
 * 创建人：刘兆明
 * 联系方式：paascloud.net@gmail.com
 * 开源地址: https://github.com/paascloud
 * 博客地址: http://blog.paascloud.net
 * 项目官网: http://paascloud.net
 */

package com.paascloud.core.config;

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.CachingConfigurerSupport;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.interceptor.KeyGenerator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * The class Redis configuration.
 *
 * https://blog.csdn.net/a67474506/article/details/52608855
 *
 * @author paascloud.net@gmail.com
 */
@Configuration
@EnableCaching
public class RedisConfiguration /*extends CachingConfigurerSupport*/ {
	/**
	 * generator key generator.
	 * redis key生成策略
	 *
	 * 注意: 该方法只是声明了key的生成策略,还未被使用,需在@Cacheable注解中指定keyGenerator
	 *      如: @Cacheable(value = "key", keyGenerator = "cacheKeyGenerator")
	 *
	 * 其他说明：
	 * spring cache缓存的key默认是通过KeyGenerator生成的，其默认生成策略如下：
	 		1. 如果方法没有参数，则使用0作为key。
	 		2. 如果只有一个参数的话则使用该参数作为key。
	 		3. 如果参数多于一个的话则使用所有参数的hashCode作为key。
	 可以看出默认的key生成策略中并没有涉及方法名称和类，这就意味着如果我们有两个参数列表相同的方法，
	 我们用相同的参数分别调用两个方法，当调用第二个方法的时候，spring cache将会返回缓存中的第一个方法的缓存值，因为他们的key是一样的。
	 比如getModel_1(Integer id)和getModel_2(Integer id)

	 所以我们需要自定义key策略来解决这个问题，将类名和方法名和参数列表一起来生成key
	 *
	 * 参考文章：https://www.jianshu.com/p/2a584aaafad3或者https://marschall.github.io/2017/10/01/better-spring-cache-key-generator.html
	 *
	 * @return the key generator
	 */
	@Bean
	public KeyGenerator keyGenerator() {
		return (target, method, params) -> {
			StringBuilder sb = new StringBuilder();
			sb.append(target.getClass().getName());
			sb.append(method.getName());
			for (Object obj : params) {
				sb.append(obj.toString());
				// 由于参数可能不同, hashCode肯定不一样, 缓存的key也需要不一样
				//sb.append(JSON.toJSONString(obj).hashCode());
			}
			return sb.toString();
		};

	}

	/**
	 * Cache manager cache manager.
	 *
	 * @param redisTemplate the redis template
	 *
	 * @return the cache manager
	 */
	@Bean
	public CacheManager cacheManager(RedisTemplate redisTemplate) {
		return new RedisCacheManager(redisTemplate);
	}

	@Bean
	public StringRedisSerializer stringRedisSerializer() {
		return new StringRedisSerializer();
	}

    /**
     * redisTemplate 默认使用jdkSerializeable进行序列化,存储二进制字节码
     * @param factory
     * @return
     */
	@Bean("redisTemplate")
	public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
		RedisTemplate<String, Object> template = new RedisTemplate<>();
		template.setConnectionFactory(factory);
		//这里使用Jackson2JsonRedisSerializer 替代默认的序列化
		Jackson2JsonRedisSerializer<Object> jackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer<>(Object.class);
		ObjectMapper om = new ObjectMapper();
		om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
		om.enableDefaultTyping(ObjectMapper.DefaultTyping.NON_FINAL);
		jackson2JsonRedisSerializer.setObjectMapper(om);
		//设置value的序列化类型为json类型
		template.setValueSerializer(jackson2JsonRedisSerializer);
		//设置key的序列化类型为String类型,key类型只能为String类型
		template.setKeySerializer(stringRedisSerializer());
		template.afterPropertiesSet();
		return template;
	}
}
