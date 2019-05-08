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

另外一种方式：本地安装
安装相应的jar包(最好要进入到对应的目录)
```
$ mvn install:install-file -DgroupId=com.alipay -DartifactId=alipay-sdk-java -Dversion=20170725114550 -Dpackaging=jar -Dfile=alipay-sdk-java-20170725114550.jar

mvn install:install-file -DgroupId=com.alipay -DartifactId=alipay-trade-sdk -Dversion=20161215 -Dpackaging=jar -Dfile=alipay-trade-sdk-20161215.jar
 
mvn install:install-file -DgroupId=com.liuzm.paascloud -DartifactId=elastic-job-lite-starter -Dversion=1.0 -Dpackaging=jar -Dfile=elastic-job-lite-starter-1.0-SNAPSHOT.jar
 
mvn install:install-file -DgroupId=com.liuzm.mybatis -DartifactId=mybatis-generator -Dversion=1.0 -Dpackaging=jar -Dfile=mybatis-generator-1.0.jar
```