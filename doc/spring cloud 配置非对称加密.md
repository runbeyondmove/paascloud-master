# 配置JDK的JCE
	下载：http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
	
jdk最好使用jdk8后期的版本，建议使用144以后的版本

# 配置
	我们需要将这里的两个jar包拷贝到我们的jdk安装目录下，我的是%JAVA_HOME%\jre\lib\security，覆盖该目录下原有的文件，切记是jdk的jre目录
	
jdk中自带的keytool工具生成密钥文件
	keytool -genkeypair -alias paascloud-key-store -keyalg RSA -keypass paascloud-keypass -keystore server.jks -storepass paascloud-storepass
	
最后会生成一个文件server.jks 使用这个文件替换paascloud-master中配置中心的server.jks的文件

然后配置文件修改
```yaml
encrypt:
 key-store:
   location: classpath:/server.jks
   password: paascloud-storepass
   alias: paascloud-key-store
   secret: paascloud-keypass
```   
   
到此 我们配置环节就做好了，下面给大家介绍一下具体使用
这里说明一下，根据笔者经验如果配置中心使用了加密，类似这样
```yaml
spring:
  cloud:
    config:
      uri: http://admin:admin@paascloud-discovery:8080/
      label: master
      profile: ${spring.profiles.active:dev}
      ignoredInterfaces:
        - docker0
        - veth.*
        - VM.*
```		
那么在使用jce做加密的时候往往会有未知的异常，所以这里为了给大家演示使用这里新起一个paascloud-example项目，找到模块paascloud-example-encrypt
- paascloud-encrypt-eureka
- paascloud-encrypt-discovery

加解密操作
加密
```
λ curl -X POST http://localhost:8080/encrypt -d 7010
```
加密结果
`AQAznUNC91gEsaaejlN8kYfBbB66l/gbONnDP2IJz9yt+5wxc8cJDkIVsvtdyVVAen2+3t5iVe4IhhQB2PWr5vARdHi1CkeufFIwKVXESXzONwpbO4kh1+WhDuD/dfHKYZWKlrucUTbT1tNyxKBHaoopIDPkKKfyqLWMnhap9YKygMyp40pEEWMmG86Fb05gn8E5mq0cSpW9vVuybHTlh701k4/Zq8soRwqX8kXc5+oH05DIoTReKTByuK82MnMF9+a+MGf/qKZgChAgWTHQVuz2yMhWySvbWEKkNjNJ3r3LdWJG844Ka0dYKSTMEGdOw4ls+p0TLw5mdMPuJDd/uuduBE+mdf7BF+EAGfyCjzF3heEqVrXUnU8kVTUnFUf4QvM=`


解密
`λ curl localhost:8080/decrypt -d AQAoax6LyiCDqHuPuWTp95iDvPbBq5lJx2SGd1cxgMeJ2QvSpUNX2XKzd9gRzG7q40/fcN9K6wmTWzlQKLhHsuTn eYOTD79pEHIeKyp5GHIhvQXopO97Hu/E4cfkS8uH6oug6w5MmLZvOW1uRe2EBTroyk2k1HtrTOv9z0FPDxXhEe+5QcyAR/ArKwsZ4axPDXjv4pFEg6R9h/H4xG0hQJ9MPhDDzn1+Swmnerjnjfel6oSQ9vDC6WG9HwT527hIG74IWXIKd/JPqCE5XvcTilf9P3prcanDT2peKdatdlYGruXBva7pZmUUuov4TiKs4Yrqzl7JAO/4GtQhm16kuAbTBbevkv4HwVlPLeMgXy/EoSC9VHTDn635qiBObg3Cgis=`

解密结果
`7010`

yaml使用
```yaml
rabbitmq:
    host:  paascloud-mq-rabbit
    port: 5672
    username: '{cipher}你的密文'
    password: '{cipher}你的密文'
```	
示例代码
https://github.com/paascloud/paascloud-example



异常
```log
org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'codec' defined in class path resource [org/springframework/cloud/stream/config/codec/kryo/KryoCodecAutoConfiguration.class]: Bean instantiation via factory method failed; nested exception is org.springframework.beans.BeanInstantiationException: Failed to instantiate [org.springframework.integration.codec.kryo.PojoCodec]: Factory method 'codec' threw exception; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'fileRegistrar' defined in class path resource [org/springframework/cloud/stream/config/codec/kryo/KryoCodecAutoConfiguration.class]: Bean instantiation via factory method failed; nested exception is org.springframework.beans.BeanInstantiationException: Failed to instantiate [org.springframework.integration.codec.kryo.KryoRegistrar]: Factory method 'fileRegistrar' threw exception; nested exception is java.lang.NoClassDefFoundError: org/objenesis/strategy/InstantiatorStrategy
	at org.springframework.beans.factory.support.ConstructorResolver.instantiateUsingFactoryMethod(ConstructorResolver.java:599)
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.instantiateUsingFactoryMethod(AbstractAutowireCapableBeanFactory.java:1181)
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBeanInstance(AbstractAutowireCapableBeanFactory.java:1075)
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.doCreateBean(AbstractAutowireCapableBeanFactory.java:513)
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBean(AbstractAutowireCapableBeanFactory.java:483)
	at org.springframework.beans.factory.support.AbstractBeanFactory$1.getObject(AbstractBeanFactory.java:312)
	at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.getSingleton(DefaultSingletonBeanRegistry.java:230)
	at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBean(AbstractBeanFactory.java:308)
	at org.springframework.beans.factory.support.AbstractBeanFactory.getBean(AbstractBeanFactory.java:197)
	at org.springframework.beans.factory.support.DefaultListableBeanFactory.preInstantiateSingletons(DefaultListableBeanFactory.java:761)
	at org.springframework.context.support.AbstractApplicationContext.finishBeanFactoryInitialization(AbstractApplicationContext.java:867)
	at org.springframework.context.support.AbstractApplicationContext.refresh(AbstractApplicationContext.java:543)
	at org.springframework.boot.context.embedded.EmbeddedWebApplicationContext.refresh(EmbeddedWebApplicationContext.java:122)
	at org.springframework.boot.SpringApplication.refresh(SpringApplication.java:693)
	at org.springframework.boot.SpringApplication.refreshContext(SpringApplication.java:360)
	at org.springframework.boot.SpringApplication.run(SpringApplication.java:303)
	at org.springframework.boot.SpringApplication.run(SpringApplication.java:1118)
	at org.springframework.boot.SpringApplication.run(SpringApplication.java:1107)
	at com.paascloud.discovery.PaasCloudDiscoveryApplication.main(PaasCloudDiscoveryApplication.java:35)
Caused by: org.springframework.beans.BeanInstantiationException: Failed to instantiate [org.springframework.integration.codec.kryo.PojoCodec]: Factory method 'codec' threw exception; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'fileRegistrar' defined in class path resource [org/springframework/cloud/stream/config/codec/kryo/KryoCodecAutoConfiguration.class]: Bean instantiation via factory method failed; nested exception is org.springframework.beans.BeanInstantiationException: Failed to instantiate [org.springframework.integration.codec.kryo.KryoRegistrar]: Factory method 'fileRegistrar' threw exception; nested exception is java.lang.NoClassDefFoundError: org/objenesis/strategy/InstantiatorStrategy
	at org.springframework.beans.factory.support.SimpleInstantiationStrategy.instantiate(SimpleInstantiationStrategy.java:189)
	at org.springframework.beans.factory.support.ConstructorResolver.instantiateUsingFactoryMethod(ConstructorResolver.java:588)
	... 18 common frames omitted
Caused by: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'fileRegistrar' defined in class path resource [org/springframework/cloud/stream/config/codec/kryo/KryoCodecAutoConfiguration.class]: Bean instantiation via factory method failed; nested exception is org.springframework.beans.BeanInstantiationException: Failed to instantiate [org.springframework.integration.codec.kryo.KryoRegistrar]: Factory method 'fileRegistrar' threw exception; nested exception is java.lang.NoClassDefFoundError: org/objenesis/strategy/InstantiatorStrategy
	at org.springframework.beans.factory.support.ConstructorResolver.instantiateUsingFactoryMethod(ConstructorResolver.java:599)
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.instantiateUsingFactoryMethod(AbstractAutowireCapableBeanFactory.java:1181)
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBeanInstance(AbstractAutowireCapableBeanFactory.java:1075)
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.doCreateBean(AbstractAutowireCapableBeanFactory.java:513)
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBean(AbstractAutowireCapableBeanFactory.java:483)
	at org.springframework.beans.factory.support.AbstractBeanFactory$1.getObject(AbstractBeanFactory.java:312)
	at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.getSingleton(DefaultSingletonBeanRegistry.java:230)
	at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBean(AbstractBeanFactory.java:308)
	at org.springframework.beans.factory.support.AbstractBeanFactory.getBean(AbstractBeanFactory.java:202)
	at org.springframework.beans.factory.support.DefaultListableBeanFactory.getBeansOfType(DefaultListableBeanFactory.java:519)
	at org.springframework.beans.factory.support.DefaultListableBeanFactory.getBeansOfType(DefaultListableBeanFactory.java:508)
	at org.springframework.context.support.AbstractApplicationContext.getBeansOfType(AbstractApplicationContext.java:1188)
	at org.springframework.cloud.stream.config.codec.kryo.KryoCodecAutoConfiguration.codec(KryoCodecAutoConfiguration.java:55)
	at org.springframework.cloud.stream.config.codec.kryo.KryoCodecAutoConfiguration$$EnhancerBySpringCGLIB$$1d4e4c96.CGLIB$codec$0(<generated>)
	at org.springframework.cloud.stream.config.codec.kryo.KryoCodecAutoConfiguration$$EnhancerBySpringCGLIB$$1d4e4c96$$FastClassBySpringCGLIB$$32134b40.invoke(<generated>)
	at org.springframework.cglib.proxy.MethodProxy.invokeSuper(MethodProxy.java:228)
	at org.springframework.context.annotation.ConfigurationClassEnhancer$BeanMethodInterceptor.intercept(ConfigurationClassEnhancer.java:358)
	at org.springframework.cloud.stream.config.codec.kryo.KryoCodecAutoConfiguration$$EnhancerBySpringCGLIB$$1d4e4c96.codec(<generated>)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.springframework.beans.factory.support.SimpleInstantiationStrategy.instantiate(SimpleInstantiationStrategy.java:162)
	... 19 common frames omitted
Caused by: org.springframework.beans.BeanInstantiationException: Failed to instantiate [org.springframework.integration.codec.kryo.KryoRegistrar]: Factory method 'fileRegistrar' threw exception; nested exception is java.lang.NoClassDefFoundError: org/objenesis/strategy/InstantiatorStrategy
	at org.springframework.beans.factory.support.SimpleInstantiationStrategy.instantiate(SimpleInstantiationStrategy.java:189)
	at org.springframework.beans.factory.support.ConstructorResolver.instantiateUsingFactoryMethod(ConstructorResolver.java:588)
	... 41 common frames omitted
Caused by: java.lang.NoClassDefFoundError: org/objenesis/strategy/InstantiatorStrategy
	at java.lang.ClassLoader.defineClass1(Native Method)
	at java.lang.ClassLoader.defineClass(ClassLoader.java:763)
	at java.security.SecureClassLoader.defineClass(SecureClassLoader.java:142)
	at java.net.URLClassLoader.defineClass(URLClassLoader.java:467)
	at java.net.URLClassLoader.access$100(URLClassLoader.java:73)
	at java.net.URLClassLoader$1.run(URLClassLoader.java:368)
	at java.net.URLClassLoader$1.run(URLClassLoader.java:362)
	at java.security.AccessController.doPrivileged(Native Method)
	at java.net.URLClassLoader.findClass(URLClassLoader.java:361)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:424)
	at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:349)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:357)
	at com.esotericsoftware.kryo.Kryo.<init>(Kryo.java:124)
	at com.esotericsoftware.kryo.Kryo.<init>(Kryo.java:149)
	at org.springframework.integration.codec.kryo.AbstractKryoRegistrar.<clinit>(AbstractKryoRegistrar.java:35)
	at org.springframework.cloud.stream.config.codec.kryo.KryoCodecAutoConfiguration.fileRegistrar(KryoCodecAutoConfiguration.java:62)
	at org.springframework.cloud.stream.config.codec.kryo.KryoCodecAutoConfiguration$$EnhancerBySpringCGLIB$$1d4e4c96.CGLIB$fileRegistrar$1(<generated>)
	at org.springframework.cloud.stream.config.codec.kryo.KryoCodecAutoConfiguration$$EnhancerBySpringCGLIB$$1d4e4c96$$FastClassBySpringCGLIB$$32134b40.invoke(<generated>)
	at org.springframework.cglib.proxy.MethodProxy.invokeSuper(MethodProxy.java:228)
	at org.springframework.context.annotation.ConfigurationClassEnhancer$BeanMethodInterceptor.intercept(ConfigurationClassEnhancer.java:358)
	at org.springframework.cloud.stream.config.codec.kryo.KryoCodecAutoConfiguration$$EnhancerBySpringCGLIB$$1d4e4c96.fileRegistrar(<generated>)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.springframework.beans.factory.support.SimpleInstantiationStrategy.instantiate(SimpleInstantiationStrategy.java:162)
	... 42 common frames omitted
Caused by: java.lang.ClassNotFoundException: org.objenesis.strategy.InstantiatorStrategy
	at java.net.URLClassLoader.findClass(URLClassLoader.java:381)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:424)
	at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:349)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:357)
	... 68 common frames omitted
```