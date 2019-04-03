## Spring Cloud 实战项目

### 项目介绍
```
功能点：
    模拟商城，完整的购物流程、后端运营平台对前端业务的支撑，和对项目的运维，有各项的监控指标和运维指标。
技术点：
       核心技术为springcloud+vue两个全家桶实现，采取了取自开源用于开源的目标，所以能用开源绝不用收费框架，整体技术栈只有
    阿里云短信服务是收费的，都是目前java前瞻性的框架，可以为中小企业解决微服务架构难题，可以帮助企业快速建站。由于服务
    器成本较高，尽量降低开发成本的原则，本项目由10个后端项目和3个前端项目共同组成。真正实现了基于RBAC、jwt和oauth2的
    无状态统一权限认证的解决方案，实现了异常和日志的统一管理，实现了MQ落地保证100%到达的解决方案。
	
	核心框架：springcloud Edgware全家桶
	安全框架：Spring Security Spring Cloud Oauth2
	分布式任务调度：elastic-job
	持久层框架：MyBatis、通用Mapper4、Mybatis_PageHelper
	数据库连接池：Alibaba Druid
	日志管理：Logback	前端框架：Vue全家桶以及相关组件
	三方服务： 邮件服务、阿里云短信服务、七牛云文件服务、钉钉机器人服务、高德地图API
```
### 平台目录结构说明


```
├─paascloud-master----------------------------父项目，公共依赖
│  │
│  ├─paascloud-eureka--------------------------微服务注册中心
│  │
│  ├─paascloud-discovery-----------------------微服务配置中心
│  │
│  ├─paascloud-monitor-------------------------微服务监控中心
│  │
│  ├─paascloud-zipkin--------------------------微服务日志采集中心
│  │
│  ├─paascloud-gateway--------------------------微服务网关中心
│  │
│  ├─paascloud-provider
│  │  │
│  │  ├─paascloud-provider-mdc------------------数据服务中心
│  │  │
│  │  ├─paascloud-provider-omc------------------订单服务中心
│  │  │
│  │  ├─paascloud-provider-opc------------------对接服务中心
│  │  │
│  │  ├─paascloud-provider-tpc------------------任务服务中心
│  │  │
│  │  └─paascloud-provider-uac------------------用户服务中心
│  │
│  ├─paascloud-provider-api
│  │  │
│  │  ├─paascloud-provider-mdc-api------------------数据服务中心API
│  │  │
│  │  ├─paascloud-provider-omc-api------------------订单服务中心API
│  │  │
│  │  ├─paascloud-provider-opc-api------------------对接服务中心API
│  │  │
│  │  ├─paascloud-provider-tpc-api------------------任务服务中心API
│  │  │
│  │  ├─paascloud-provider-sdk-api------------------可靠消息服务API
│  │  │
│  │  └─paascloud-provider-uac-api------------------用户服务中心API
│  │
│  ├─paascloud-common
│  │  │
│  │  ├─paascloud-common-base------------------公共POJO基础包
│  │  │
│  │  ├─paascloud-common-config------------------公共配置包
│  │  │
│  │  ├─paascloud-common-core------------------微服务核心依赖包
│  │  │
│  │  ├─paascloud-common-util------------------公共工具包
│  │  │
│  │  ├─paascloud-common-zk------------------zookeeper配置（zk注册中心及全局唯一ID生成器）
│  │  │
│  │  ├─paascloud-security-app------------------公共无状态安全认证
│  │  │
│  │  ├─paascloud-security-core------------------安全服务核心包
│  │  │
│  │  └─paascloud-security-feign------------------基于auth2的feign配置
│  │
│  ├─paascloud-generator
│  │  │
│  │  ├─paascloud-generator-mdc------------------数据服务中心Mybatis Generator
│  │  │
│  │  ├─paascloud-generator-omc------------------数据服务中心Mybatis Generator
│  │  │
│  │  ├─paascloud-generator-opc------------------数据服务中心Mybatis Generator
│  │  │
│  │  ├─paascloud-generator-tpc------------------数据服务中心Mybatis Generator
│  │  │
│  │  └─paascloud-generator-uac------------------数据服务中心Mybatis Generator




```


### 特殊说明


```
这里做一个解释由于微服务的拆分受制于服务器，这里我做了微服务的合并，比如OAuth2的认证服务中心和用户中心合并，
统一的one service服务中心和用户认证中心合并，支付中心和订单中心合并，其实这也是不得已而为之，
只是做了业务微服务中心的合并，并没有将架构中的 注册中心 监控中心 服务发现中心进行合并。
```

在使用 Spring Cloud 体系来构建微服务的过程中，用户请求是通过网关(ZUUL 或 Spring APIGateway)以 HTTP 协议来传输信息，
API 网关将自己注册为 Eureka 服务治理下的应用，同时也从 Eureka 服务中获取所有其他微服务的实例信息。
搭建 OAuth2 认证授权服务，并不是给每个微服务调用，而是通过 API 网关进行统一调用来对网关后的微服务做前置过滤，
所有的请求都必须先通过 API 网关，API 网关在进行路由转发之前对该请求进行前置校验，实现对微服务系统中的其他的服务接口的安全与权限校验。


### 作者介绍

```
Spring Cloud 爱好者,现就任于鲜易供应链平台研发部.
```

### QQ群交流
 ①：519587831（满）  
 ②：873283104（满）  
 ③：882458726（满）  
 ④：693445268    
 ⑤：813682656    
 ⑥：797334670    
 ⑦：797876073    
 ⑧：814712305    
 ⑨：……    

## 配套项目

```
后端项目：https://github.com/paascloud/paascloud-master 
         https://gitee.com/paascloud/paascloud-master
登录入口：https://github.com/paascloud/paascloud-login-web
         https://gitee.com/paascloud/paascloud-login-web
后端入口：https://github.com/paascloud/paascloud-admin-web
         https://gitee.com/paascloud/paascloud-admin-web
前端入口：https://github.com/paascloud/paascloud-mall-web
         https://gitee.com/paascloud/paascloud-mall-web
```

### 传送门
- 博客入口： http://blog.paascloud.net
- 后端入口： http://admin.paascloud.net (支持微信登录体验)
- 模拟商城: http://mall.paascloud.net (支持微信登录体验)
- 文档手册: http://document.paascloud.net
- github: https://github.com/paascloud
- 操作手册: http://blog.paascloud.net/2018/06/10/paascloud/doc/

### 架构图

![项目架构图](http://img.paascloud.net/paascloud/doc/paascloud-project.png)


## 这个项目为什么同时使用了Zookeeper和Eureka？
总结：  
著名的CAP理论指出，一个分布式系统不可能同时满足C(一致性)、A(可用性)和P(分区容错性)。  
由于分区容错性在是分布式系统中必须要保证的，因此我们只能在A和C之间进行权衡。  
在此Zookeeper保证的是CP（即任何时刻对ZooKeeper的访问请求能得到一致的数据结果，同时系统对网络分割具备容错性；但是它不能保证每次服务请求的可用性；
ZooKeeper是分布式协调服务，它的职责是保证数据（注：配置数据，状态数据）在其管辖下的所有服务之间保持同步、一致）, 
而Eureka则是AP。

**注册服务是必须可用的**

Zookeeper选举期间整个zk集群是不可用的，而只要有一台Eureka还在，就能保证注册服务可用(保证可用性)

分区容错性：单台服务器，或多台服务器出问题（主要是网络问题）后，正常服务的服务器依然能正常提供服务，并且满足设计好的一致性和可用性 
重点在于：部分服务器因网络问题，业务依然能够继续运行

1. [Zookeeper用作注册中心的原理](https://blog.csdn.net/ljheee/article/details/81251897)
2. [Eureka与Zookeeper服务注册中心比较](https://blog.csdn.net/qq_36512792/article/details/79557564)




# 技术选型
##  后端架构
```
spring-cloud Edgware.RELEASE
Spring Cloud Eureka
spring cloud config
spring cloud security
Spring Cloud Feign
Spring Cloud Zuul
Spring Cloud Hystrix
Spring Cloud Turbine
spring Cloud Sleuth Zipkin
Spring Cloud Stream 
Binder Rabbit
Spring Cloud Oauth2
Spring Cloud Sleuth
elastic-job
Spring Boot
Spring Boot Mail
Swagger2
MyBatis
通用Mapper
Mybatis_PageHelper
Freemarker
RabbitMQ
RocketMQ
Druid
MySQL
Redis
Zookeeper
钉钉机器人
阿里云短信服务
七牛云文件服务
...
```

## 前端架构
```
Vue全家桶以及相关组件
"axios": "^0.17.1",
"crypto-js": "^3.1.9-1",
"echarts": "^3.8.5",
"element-ui": "^2.0.10",
"font-awesome": "^4.7.0",
"js-cookie": "^2.2.0",
"lockr": "^0.8.4",
"nprogress": "^0.2.0",
"vue": "^2.5.9",
"vue-infinite-scroll": "^2.0.2",
"vue-lazyload": "^1.1.4",
"vue-router": "^3.0.1",
"vuex": "^3.0.1"
```

# 配置域名
```
127.0.0.1 dev-login.paascloud.net
127.0.0.1 dev-admin.paascloud.net
127.0.0.1 dev-api.paascloud.net
127.0.0.1 dev-mall.paascloud.net
127.0.0.1 paascloud-discovery
127.0.0.1 paascloud-eureka
127.0.0.1 paascloud-gateway
127.0.0.1 paascloud-monitor
127.0.0.1 paascloud-zipkin
127.0.0.1 paascloud-provider-uac
127.0.0.1 paascloud-provider-mdc
127.0.0.1 paascloud-provider-omc
127.0.0.1 paascloud-provider-opc


192.168.241.21 paascloud-db-mysql
192.168.241.21 paascloud-db-redis
192.168.241.21 paascloud-mq-rabbit
192.168.241.21 paascloud-mq-rocket
192.168.241.21 paascloud-provider-zk

192.168.241.101 paascloud-zk-01
192.168.241.102 paascloud-zk-02
192.168.241.103 paascloud-zk-03
```

# nginx配置
```
server {
    listen       80;
    server_name  dev-admin.paascloud.net;
    location / {
        proxy_pass http://localhost:7020;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}
server {
    listen       80;
    server_name  dev-login.paascloud.net;
    location / {
        proxy_pass http://localhost:7010;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}
server {
    listen       80;
    server_name  dev-mall.paascloud.net;
    location / {
        proxy_pass http://localhost:7030;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}
server {
    listen       80;
    server_name  dev-api.paascloud.net;
    location ~ {
        proxy_pass   http://localhost:7979;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}
```

# 微服务启动顺序
1. paascloud-eureka
2. paascloud-discovery
3. paascloud-provider-uac
4. paascloud-gateway
5. 剩下微服务无启动数序要求


# 其他服务使用配置中心配置记得要参考paascloud-provider-uac项目
Config支持我们使用的请求的参数规则为：

> - / { 应用名 } / { 环境名 } [ / { 分支名 } ]
> - / { 应用名 } - { 环境名 }.yml
> - / { 应用名 } - { 环境名 }.properties
> - / { 分支名 } / { 应用名 } - { 环境名 }.yml
> - / { 分支名 } / { 应用名 } - { 环境名 }.properties

在paascloud-provider-uac中使用的最后一种
如果配置正确的话，那discovery client的日志如下：
```log
2019-04-03 16:56:02.691  INFO [bootstrap,,,] [paascloud-provider-uac,,,,] 9620 --- [  restartedMain] c.c.c.ConfigServicePropertySourceLocator : Fetching config from server at: http://10.53.144.48:8080/
2019-04-03 16:56:04.941  INFO [bootstrap,,,] [paascloud-provider-uac,,,,] 9620 --- [  restartedMain] c.c.c.ConfigServicePropertySourceLocator : Located environment: name=paascloud-provider-uac, profiles=[dev], label=outside-dev, version=2a6b6d54e28a4abbaf307aafe19587594f4944dc, state=null
2019-04-03 16:56:04.941  INFO [bootstrap,,,] [paascloud-provider-uac,,,,] 9620 --- [  restartedMain] b.c.PropertySourceBootstrapConfiguration : Located property source: CompositePropertySource [name='configService', propertySources=[MapPropertySource {name='configClient'}, MapPropertySource {name='https://github.com/runbeyondmove/paascloud-config-repo_20190331.git/paascloud-provider-uac-dev.yml'}, MapPropertySource {name='https://github.com/runbeyondmove/paascloud-config-repo_20190331.git/application-dev.yml'}]]
2019-04-03 16:56:05.004  INFO [bootstrap,,,] [paascloud-provider-uac,,,,] 9620 --- [  restartedMain] com.paascloud.PaasCloudUacApplication    : The following profiles are active: outside-dev
```

而discovery server的日志会出现以下几行
```log
2019-04-03 17:24:53.448  INFO 12508 --- [trap-executor-0] c.n.d.s.r.aws.ConfigClusterResolver      : Resolving eureka endpoints via configuration
2019-04-03 17:24:55.684  INFO 12508 --- [io-8080-exec-10] .c.s.e.MultipleJGitEnvironmentRepository : Fetched for remote outside-dev and found 1 updates
2019-04-03 17:24:55.780  INFO 12508 --- [io-8080-exec-10] s.c.a.AnnotationConfigApplicationContext : Refreshing org.springframework.context.annotation.AnnotationConfigApplicationContext@73425db3: startup date [Wed Apr 03 17:24:55 CST 2019]; root of context hierarchy
2019-04-03 17:24:55.796  INFO 12508 --- [io-8080-exec-10] f.a.AutowiredAnnotationBeanPostProcessor : JSR-330 'javax.inject.Inject' annotation found and supported for autowiring
2019-04-03 17:24:55.796  INFO 12508 --- [io-8080-exec-10] o.s.c.c.s.e.NativeEnvironmentRepository  : Adding property source: file:/D:/data/config/paascloud-config-repo/paascloud-provider-uac-dev.yml
2019-04-03 17:24:55.796  INFO 12508 --- [io-8080-exec-10] o.s.c.c.s.e.NativeEnvironmentRepository  : Adding property source: file:/D:/data/config/paascloud-config-repo/application-dev.yml
2019-04-03 17:24:55.796  INFO 12508 --- [io-8080-exec-10] s.c.a.AnnotationConfigApplicationContext : Closing org.springframework.context.annotation.AnnotationConfigApplicationContext@73425db3: startup date [Wed Apr 03 17:24:55 CST 2019]; root of context hierarchy
```


# 异常处理
参数抛指定的参数异常， 业务异常必须抛出指定编码。 正例：
`throw new UacBizException(ErrorCodeEnum.UAC10011021);`
如有业务编码 需要抛出指定业务编码
`throw new UacBizException(ErrorCodeEnum.UAC10013002, menuId);`
ErrorCodeEnum枚举实现详见代码
```
public int deleteUacMenuById(Long id, LoginAuthDto loginAuthDto) {
        Preconditions.checkArgument(id != null, "菜单id不能为空");
        int result;
        // 获取当前菜单信息
        UacMenu uacMenuQuery = new UacMenu();
        uacMenuQuery.setId(id);
        uacMenuQuery = mapper.selectOne(uacMenuQuery);
        if (PublicUtil.isEmpty(uacMenuQuery)) {
            throw new UacBizException(ErrorCodeEnum.UAC10013003, id);
        }

        ...
        return result;
    }
```

# web全局异常
```
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {
    @Resource
    private TaskExecutor taskExecutor;
    @Value("${spring.profiles.active}")
    String profile;
    @Value("${spring.application.name}")
    String applicationName;
    @Resource
    private MdcExceptionLogFeignApi mdcExceptionLogFeignApi;

    /**
     * 参数非法异常.
     *
     * @param e the e
     *
     * @return the wrapper
     */
    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseStatus(HttpStatus.OK)
    @ResponseBody
    public Wrapper illegalArgumentException(IllegalArgumentException e) {
        log.error("参数非法异常={}", e.getMessage(), e);
        return WrapMapper.wrap(ErrorCodeEnum.GL99990100.code(), e.getMessage());
    }

    /**
     * 业务异常.
     *
     * @param e the e
     *
     * @return the wrapper
     */
    @ExceptionHandler(BusinessException.class)
    @ResponseStatus(HttpStatus.OK)
    @ResponseBody
    public Wrapper businessException(BusinessException e) {
        log.error("业务异常={}", e.getMessage(), e);
        return WrapMapper.wrap(e.getCode() == 0 ? Wrapper.ERROR_CODE : e.getCode(), e.getMessage());
    }


    /**
     * 全局异常.
     *
     * @param e the e
     *
     * @return the wrapper
     */
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    @ResponseBody
    public Wrapper exception(Exception e) {
        log.info("保存全局异常信息 ex={}", e.getMessage(), e);
        taskExecutor.execute(() -> {
            GlobalExceptionLogDto globalExceptionLogDto = new GlobalExceptionLogDto().getGlobalExceptionLogDto(e, profile, applicationName);
            mdcExceptionLogFeignApi.saveAndSendExceptionLog(globalExceptionLogDto);
        });
        return WrapMapper.error();
    }
}
```
# Rpc全局异常
```
@Slf4j
public class Oauth2FeignErrorInterceptor implements ErrorDecoder {
    private final ErrorDecoder defaultErrorDecoder = new Default();

    /**
     * Decode exception.
     *
     * @param methodKey the method key
     * @param response  the response
     *
     * @return the exception
     */
    @Override
    public Exception decode(final String methodKey, final Response response) {
        if (response.status() >= HttpStatus.BAD_REQUEST.value() && response.status() < HttpStatus.INTERNAL_SERVER_ERROR.value()) {
            return new HystrixBadRequestException("request exception wrapper");
        }

        ObjectMapper mapper = new ObjectMapper();
        try {
            HashMap map = mapper.readValue(response.body().asInputStream(), HashMap.class);
            Integer code = (Integer) map.get("code");
            String message = (String) map.get("message");
            if (code != null) {
                ErrorCodeEnum anEnum = ErrorCodeEnum.getEnum(code);
                if (anEnum != null) {
                    if (anEnum == ErrorCodeEnum.GL99990100) {
                        throw new IllegalArgumentException(message);
                    } else {
                        throw new BusinessException(anEnum);
                    }
                } else {
                    throw new BusinessException(ErrorCodeEnum.GL99990500, message);
                }
            }
        } catch (IOException e) {
            log.info("Failed to process response body");
        }
        return defaultErrorDecoder.decode(methodKey, response);
    }
}
```






# 一些总结
## 1. 授权配置
授权配置提供器，各个模块和业务系统可以通过实现此接口向系统添加授权配置。
com.paascloud.security.core.authorize.AuthorizeConfigProvider，可参考实现PcAuthorizeConfigProvider

## 2. 表单登陆配置
com.paascloud.security.core.authentication.FormAuthenticationConfig
