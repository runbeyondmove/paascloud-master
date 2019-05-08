* 数据库脚本和三方Jar包

```
https://download.csdn.net/download/liu_zhaoming/10296447
```

* 配置中心git找不到

```
https://gitee.com/passcloud/paascloud-master/issues/IIEP5
```

* elastic-job-lite-starter jar包找不到

```
https://github.com/paascloud/elastic-job-lite-starter-master
```

* 配置非对称加密

```
http://blog.paascloud.net/2018/03/25/springcloud/config/springcloud-config-encrypt/
```

* 友情提供私服

```
http://blog.paascloud.net/2018/03/26/springcloud/nexus/maven-nexus-use/
```


Redis错误解决
```log
Caused by: redis.clients.jedis.exceptions.JedisDataException: DENIED Redis is running in protected mode because protected mode is enabled, no bind address was specified, no authentication password is requested to clients. In this mode connections are only accepted from the loopback interface. If you want to connect from external computers to Redis you may adopt one of the following solutions: 1) Just disable protected mode sending the command 'CONFIG SET protected-mode no' from the loopback interface by connecting to Redis from the same host the server is running, however MAKE SURE Redis is not publicly accessible from internet if you do so. Use CONFIG REWRITE to make this change permanent. 2) Alternatively you can just disable the protected mode by editing the Redis configuration file, and setting the protected mode option to 'no', and then restarting the server. 3) If you started the server manually just for testing, restart it with the '--protected-mode no' option. 4) Setup a bind address or an authentication password. NOTE: You only need to do one of the above things in order for the server to start accepting connections from the outside.
at redis.clients.jedis.Protocol.processError(Protocol.java:127)
at redis.clients.jedis.Protocol.process(Protocol.java:161)
at redis.clients.jedis.Protocol.read(Protocol.java:215)
at redis.clients.jedis.Connection.readProtocolWithCheckingBroken(Connection.java:340)
at redis.clients.jedis.Connection.getStatusCodeReply(Connection.java:239)
at redis.clients.jedis.BinaryJedis.auth(BinaryJedis.java:2139)
at redis.clients.jedis.JedisFactory.makeObject(JedisFactory.java:108)
at org.apache.commons.pool2.impl.GenericObjectPool.create(GenericObjectPool.java:868)
at org.apache.commons.pool2.impl.GenericObjectPool.borrowObject(GenericObjectPool.java:435)
at org.apache.commons.pool2.impl.GenericObjectPool.borrowObject(GenericObjectPool.java:363)
at redis.clients.util.Pool.getResource(Pool.java:49)
... 50 common frames omitted
```
解决办法
`protected-mode no  `

# paascloud-provider
## spring cloud oauth2 feign 遇到的坑
OAuth2FeignAutoConfiguration类主要是feign组件利用Oauth2的认证token来访问资源服务器上的资源。
OAuth2FeignRequestInterceptor 作为oauth2的request请求的拦截器。对于每次请求我们自动设置Oauth2的AccessToken 头信息。


## Waiting for changelog lock....
```log
Waiting for changelog lock....
Waiting for changelog lock....
Waiting for changelog lock....
Waiting for changelog lock....
Waiting for changelog lock....
Waiting for changelog lock....
Waiting for changelog lock....
Liquibase Update Failed: Could not acquire change log lock.  Currently locked by SomeComputer (192.168.15.X) since 2013-03-20 13:39
SEVERE 2013-03-20 16:59:liquibase: Could not acquire change log lock.  Currently locked by SomeComputer (192.168.15.X) since 2013-03-20 13:39
liquibase.exception.LockException: Could not acquire change log lock.  Currently locked by SomeComputer (192.168.15.X) since 2013-03-20 13:39
        at liquibase.lockservice.LockService.waitForLock(LockService.java:81)
        at liquibase.Liquibase.tag(Liquibase.java:507)
        at liquibase.integration.commandline.Main.doMigration(Main.java:643)
        at liquibase.integration.commandline.Main.main(Main.java:116)
```
解决办法：
```sql
UPDATE DATABASECHANGELOGLOCK SET LOCKED=FALSE,LOCKGRANTED=null, LOCKEDBY=null where ID=1;
DELETE FROM DATABASECHANGELOGLOCK;
```

## paascloud-provider-uac
### yml错误提示version: @project.version@
```log
at org.springframework.context.event.SimpleApplicationEventMulticaster.invokeListener(SimpleApplicationEventMulticaster.java:167)
at org.springframework.context.event.SimpleApplicationEventMulticaster.multicastEvent(SimpleApplicationEventMulticaster.java:139)
at org.springframework.context.event.SimpleApplicationEventMulticaster.multicastEvent(SimpleApplicationEventMulticaster.java:122)
at org.springframework.boot.context.event.EventPublishingRunListener.environmentPrepared(EventPublishingRunListener.java:74)
at org.springframework.boot.SpringApplicationRunListeners.environmentPrepared(SpringApplicationRunListeners.java:54)
at org.springframework.boot.SpringApplication.prepareEnvironment(SpringApplication.java:325)
at org.springframework.boot.SpringApplication.run(SpringApplication.java:296)
at org.springframework.boot.SpringApplication.run(SpringApplication.java:1118)
at org.springframework.boot.SpringApplication.run(SpringApplication.java:1107)
at com.paascloud.PaasCloudUacApplication.main(PaasCloudUacApplication.java:35)
at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
at sun.reflect.NativeMethodAccessorImpl.invoke(Unknown Source)
at sun.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)
at java.lang.reflect.Method.invoke(Unknown Source)
at org.springframework.boot.devtools.restart.RestartLauncher.run(RestartLauncher.java:49)
Caused by: org.yaml.snakeyaml.scanner.ScannerException: while scanning for the next token
found character '@' that cannot start any token. (Do not use @ for indentation)
 in 'reader', line 47, column 12:
   version: @project.version@
```
解决办法：
```yaml
		info:
         app:
        name: "@project.artifactId@"
        encoding: '@project.build.sourceEncoding@'
        java:
          source: '@java.version@'
          target: '@java.version@'
```

# paascloud-geteway
## 1.错误No Spring Session store is configured: set the 'spring.session.store-type' property
```log
org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'org.springframework.boot.autoconfigure.session.SessionAutoConfiguration$SessionRepositoryValidator': Invocation of init method failed; nested exception is java.lang.IllegalArgumentException: No Spring Session store is configured: set the 'spring.session.store-type' property
    at org.springframework.beans.factory.annotation.InitDestroyAnnotationBeanPostProcessor.postProcessBeforeInitialization(InitDestroyAnnotationBeanPostProcessor.java:137)
    at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.applyBeanPostProcessorsBeforeInitialization(AbstractAutowireCapableBeanFactory.java:409)
    at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.initializeBean(AbstractAutowireCapableBeanFactory.java:1620)
    at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.doCreateBean(AbstractAutowireCapableBeanFactory.java:555)
    at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBean(AbstractAutowireCapableBeanFactory.java:483)
    at org.springframework.beans.factory.support.AbstractBeanFactory$1.getObject(AbstractBeanFactory.java:306)
    at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.getSingleton(DefaultSingletonBeanRegistry.java:230)
    at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBean(AbstractBeanFactory.java:302)
    at org.springframework.beans.factory.support.AbstractBeanFactory.getBean(AbstractBeanFactory.java:197)
    at org.springframework.beans.factory.support.DefaultListableBeanFactory.preInstantiateSingletons(DefaultListableBeanFactory.java:761)
    at org.springframework.context.support.AbstractApplicationContext.finishBeanFactoryInitialization(AbstractApplicationContext.java:866)
    at org.springframework.context.support.AbstractApplicationContext.refresh(AbstractApplicationContext.java:542)
    at org.springframework.boot.context.embedded.EmbeddedWebApplicationContext.refresh(EmbeddedWebApplicationContext.java:122)
    at org.springframework.boot.SpringApplication.refresh(SpringApplication.java:693)
    at org.springframework.boot.SpringApplication.refreshContext(SpringApplication.java:360)
    at org.springframework.boot.SpringApplication.run(SpringApplication.java:303)
    at org.springframework.boot.SpringApplication.run(SpringApplication.java:1118)
    at org.springframework.boot.SpringApplication.run(SpringApplication.java:1107)
    at com.paascloud.gateway.PaasCloudGatewayApplication.main(PaasCloudGatewayApplication.java:27)
Caused by: java.lang.IllegalArgumentException: No Spring Session store is configured: set the 'spring.session.store-type' property`
```
解决办法：
```yaml
	spring:  
    	session:
			store-type: none
```

