package com.paascloud.core.enums;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;

import java.util.List;
import java.util.Map;

/**
 * OAuth2 授权模式
 * @author: lijingrun
 * @createTime： 2019/8/22
 * @version: 1.0.0
 */
public enum AuthorizedGrantTypeEnum {
    AUTHORIZATION_CODE("code", "授权码模式"),
    IMPLICIT("token", "简化模式"),
    RESOURCE_OWNER_PASSWORD_CREDENTIALS("password", "密码模式"),
    CLIENT_CREDENTIALS("client_credentials", "客户端模式"),
    REFRESH_TOKEN("refresh_token", "更新令牌"),
    ;

    /**
     * The Type.
     */
    String type;
    /**
     * The Name.
     */
    String description;

    AuthorizedGrantTypeEnum(String type, String description) {
        this.type = type;
        this.description = description;
    }

    /**
     * Gets type.
     *
     * @return the type
     */
    public String getType() {
        return type;
    }

    /**
     * Gets name.
     *
     * @return the name
     */
    public String getDescription() {
        return description;
    }

    /**
     * Gets name.
     *
     * @param type the type
     *
     * @return the name
     */
    public static String getName(String type) {
        for (AuthorizedGrantTypeEnum ele : AuthorizedGrantTypeEnum.values()) {
            if (type.equals(ele.getType())) {
                return ele.getDescription();
            }
        }
        return null;
    }

    /**
     * Gets enum.
     *
     * @param type the type
     *
     * @return the enum
     */
    public static AuthorizedGrantTypeEnum getEnum(String type) {
        if (type == null) {
            return null;
        }
        for (AuthorizedGrantTypeEnum ele : AuthorizedGrantTypeEnum.values()) {
            if (type.equals(ele.getType())) {
                return ele;
            }
        }
        return null;
    }

    /**
     * Gets list.
     *
     * @return the list
     */
    public static List<Map<String, Object>> getList() {
        List<Map<String, Object>> list = Lists.newArrayList();
        for (AuthorizedGrantTypeEnum ele : AuthorizedGrantTypeEnum.values()) {
            Map<String, Object> map = Maps.newHashMap();
            map.put("key", ele.getType());
            map.put("value", ele.getDescription());
            list.add(map);
        }
        return list;
    }
}
