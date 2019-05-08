来源文章：https://blog.csdn.net/qq_37105358/article/details/86368774

1. 在项目的根 pom 文件中添加私服仓库的配置地址等相关信息:
```xml
<repositories>
    <repository>
        <id>keppel</id>
        <name>keppel</name>
        <url>http://45.78.44.134:8081/nexus/content/repositories/keppel/</url>
        <releases>
            <enabled>true</enabled>
        </releases>
        <snapshots>
            <enabled>true</enabled>
        </snapshots>
    </repository>
</repositories>

<pluginRepositories>
    <pluginRepositories>
        <id>keppel</id>
        <name>keppel</name>
        <url>http://45.78.44.134:8081/nexus/content/repositories/keppel/</url>
        <releases>
            <enabled>true</enabled>
        </releases>
        <snapshots>
            <enabled>true</enabled>
        </snapshots>
    </pluginRepository>
</pluginRepositories>
```

2. 修改相关依赖
```xml
<!-- mybatis-generator的依赖地址: -->
<dependency>
    <groupId>com.keppel.mybatis</groupId>
    <artifactId>mybatis-generator</artifactId>
    <version>1.0</version>
</dependency>

<!-- elastic-job-lite-starter的依赖地址: -->
<dependency>
    <groupId>com.keppel.paascloud</groupId>
    <artifactId>elastic-job-lite-starter</artifactId>
    <version>1.0</version>
</dependency>

<!--阿里支付的相关包依赖: -->
<dependency>
    <groupId>com.keppel.alipay</groupId>
    <artifactId>alipay-sdk-java</artifactId>
    <version>20170725114550</version>
</dependency>
<dependency>
    <groupId>com.keppel.alipay</groupId>
    <artifactId>alipay-trade-sdk</artifactId>
    <version>20161215</version>
</dependency>
```
