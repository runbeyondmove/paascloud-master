# Spring MVC自定义消息转换器(可解决Long类型数据传入前端精度丢失的问题)
参考文章：[Spring MVC自定义消息转换器(可解决Long类型数据传入前端精度丢失的问题)](https://blog.csdn.net/u014534808/article/details/80518006)

## 前言
对于Long 类型的数据，如果我们在Controller层通过@ResponseBody将返回数据自动转换成json时，不做任何处理，而直接传给前端的话，在Long长度大于17位时会出现精度丢失的问题。

@ResponseBody注解的作用是将controller的方法返回的对象通过适当的转换器(默认使用MappingJackson2HttpMessageConverte（Spring 4.x以下使用的是MappingJackson2HttpMessageConverte）)转换为指定的格式之后，写入到response对象的body区，  
需要注意的是，在使用此注解之后不会再走试图处理器，而是直接将数据写入到输入流中，他的效果等同于通过response对象输出指定格式的数据。

作用等同于response.getWriter.write(JSONObject.fromObject(user).toString());

如何避免精度丢失呢？最常用的办法就是待转化的字段统一转成String类型

## 方法一 jackson注解
```xml
<dependency>
     <groupId>com.fasterxml.jackson.core</groupId>
     <artifactId>jackson-annotations</artifactId>
     <version>2.8.6</version>
 </dependency>
 <dependency>
     <groupId>com.fasterxml.jackson.core</groupId>
     <artifactId>jackson-databind</artifactId>
     <version>2.8.6</version>
 </dependency>
```

```java
package com.paascloud.helper;


import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;

import java.io.IOException;

/**
 * Long 类型字段序列化时转为字符串，避免js丢失精度
 */
public class LongJsonSerializer extends JsonSerializer<Long> {
	/**
	 * Serialize.
	 *
	 * @param value              the value
	 * @param jsonGenerator      the json generator
	 * @param serializerProvider the serializer provider
	 *
	 * @throws IOException the io exception
	 */
	@Override
	public void serialize(Long value, JsonGenerator jsonGenerator, SerializerProvider serializerProvider) throws IOException {
		String text = (value == null ? null : String.valueOf(value));
		if (text != null) {
			jsonGenerator.writeString(text);
		}
	}
}
```

```java
package com.paascloud.helper;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

/**
 * 将字符串转为Long
 */
public class LongJsonDeserializer extends JsonDeserializer<Long> {
	private static final Logger logger = LoggerFactory.getLogger(LongJsonDeserializer.class);

	/**
	 * Deserialize long.
	 *
	 * @param jsonParser             the json parser
	 * @param deserializationContext the deserialization context
	 *
	 * @return the long
	 *
	 */
	@Override
	public Long deserialize(JsonParser jsonParser, DeserializationContext deserializationContext) {
		String value = null;
		try {
			value = jsonParser.getText();
		} catch (IOException e) {
			e.printStackTrace();
		}
		try {
			return value == null ? null : Long.parseLong(value);
		} catch (NumberFormatException e) {
			logger.error("解析长整形错误", e);
			return null;
		}
	}
}
```

```java
@Data
public class BaseEntity {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@JsonSerialize(using = LongJsonSerializer.class)
	@JsonDeserialize(using = LongJsonDeserializer.class)
	private Long id;
}
```

发现在List中还有问题

## 方法二
```xml
<!-- https://mvnrepository.com/artifact/com.fasterxml.jackson.core/jackson-databind -->
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.9.8</version>
</dependency>

<!-- https://mvnrepository.com/artifact/com.fasterxml.jackson.module/jackson-module-parameter-names -->
<dependency>
    <groupId>com.fasterxml.jackson.module</groupId>
    <artifactId>jackson-module-parameter-names</artifactId>
    <version>2.9.8</version>
</dependency>

<!-- https://mvnrepository.com/artifact/com.fasterxml.jackson.datatype/jackson-datatype-jdk8 -->
<dependency>
    <groupId>com.fasterxml.jackson.datatype</groupId>
    <artifactId>jackson-datatype-jdk8</artifactId>
    <version>2.9.8</version>
</dependency>

<!-- https://mvnrepository.com/artifact/com.fasterxml.jackson.datatype/jackson-datatype-jsr310 -->
<dependency>
    <groupId>com.fasterxml.jackson.datatype</groupId>
    <artifactId>jackson-datatype-jsr310</artifactId>
    <version>2.9.8</version>
</dependency>
```

注入bean
```java
@Bean
public ObjectMapper ObjectMapper(){
	SimpleModule simpleModule = new SimpleModule();
	simpleModule.addSerializer(Long.class, ToStringSerializer.instance);
	simpleModule.addSerializer(Long.TYPE, ToStringSerializer.instance);
	ObjectMapper objectMapper = new ObjectMapper()
			.registerModule(new ParameterNamesModule())
			.registerModule(new Jdk8Module())
			.registerModule(new JavaTimeModule())
			.registerModule(simpleModule);
	objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
//		SerializerProvider serializerProvider = objectMapper.getSerializerProvider();
//		serializerProvider.setNullValueSerializer(new JsonSerializer<Object>() {
//			@Override
//			public void serialize(Object o, JsonGenerator jsonGenerator, SerializerProvider serializerProvider) throws IOException {
//				jsonGenerator.writeString("");
//			}
//
//		});
		return objectMapper;
	}
```

解决现有问题



# SpringBoot 自定义消息转换器
 

首先我们需要明白一个概念：<font color="red">springboot中很多配置都是使用了条件注解进行判断一个配置或者引入的类是否在容器中存在，如果存在会如何，如果不存在会如何。</font>

也就是说，<font color="red">有些配置会在springboot中有默认配置，前提是你没有配置，这样来起到简化配置作用。如果你配置了，容器就不会为你再去默认配置。</font>

配置消息转化器的两种方法：

## 方法一：自定义消息转化器
只需要在@Configuration的类中添加消息转化器的@bean加入到Spring容器，就会被Spring Boot自动加入到容器中。

自定义字符串转换器：
```java
//此方法位于一个有@Configuration注解的类中
@Bean
public StringHttpMessageConverter stringHttpMessageConverter(){
    StringHttpMessageConverter converter  = new StringHttpMessageConverter(Charset.forName("UTF-8"));
    return converter;
}
```

自定义fastjson转换器：
```java
@Bean
public HttpMessageConverters fastJsonHttpMessageConverters(){
    //1.需要定义一个convert转换消息的对象;
    FastJsonHttpMessageConverter fastJsonHttpMessageConverter = new FastJsonHttpMessageConverter();
    //2:添加fastJson的配置信息;
    FastJsonConfig fastJsonConfig = new FastJsonConfig();
    fastJsonConfig.setSerializerFeatures(SerializerFeature.PrettyFormat);
    //3处理中文乱码问题
    List<MediaType> fastMediaTypes = new ArrayList<>();
    fastMediaTypes.add(MediaType.APPLICATION_JSON_UTF8);
    //4.在convert中添加配置信息.
    fastJsonHttpMessageConverter.setSupportedMediaTypes(fastMediaTypes);
    fastJsonHttpMessageConverter.setFastJsonConfig(fastJsonConfig);
    HttpMessageConverter<?> converter = fastJsonHttpMessageConverter;
    return new HttpMessageConverters(converter);

}
```

## 方法二：在继承WebMvcConfigurerAdapter的类中重写（覆盖）configureMessageConverters方法
自定义字符串转换器：
```java
// 自定义消息转化器的第二种方法
@Override
public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
    StringHttpMessageConverter converter  = new StringHttpMessageConverter(Charset.forName("UTF-8"));
    converters.add(converter);
}
```

自定义fastjson转换器：
```java
@Override
public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
    super.configureMessageConverters(converters);
    //1.需要定义一个convert转换消息的对象;
    FastJsonHttpMessageConverter fastJsonHttpMessageConverter = new FastJsonHttpMessageConverter();
    //2.添加fastJson的配置信息，比如：是否要格式化返回的json数据;
    FastJsonConfig fastJsonConfig = new FastJsonConfig();
    fastJsonConfig.setSerializerFeatures(SerializerFeature.PrettyFormat);
    //3处理中文乱码问题
    List<MediaType> fastMediaTypes = new ArrayList<>();
    fastMediaTypes.add(MediaType.APPLICATION_JSON_UTF8);
    //4.在convert中添加配置信息.
    fastJsonHttpMessageConverter.setSupportedMediaTypes(fastMediaTypes);
    fastJsonHttpMessageConverter.setFastJsonConfig(fastJsonConfig);
    //5.将convert添加到converters当中.
    converters.add(fastJsonHttpMessageConverter);
}
```
