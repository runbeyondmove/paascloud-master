/*
Navicat MySQL Data Transfer

Source Server         : paascloud-dev
Source Server Version : 50719
Source Host           : 192.168.241.21:3306
Source Database       : paascloud_tpc

Target Server Type    : MYSQL
Target Server Version : 50719
File Encoding         : 65001

Date: 2018-03-19 16:19:10
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for JOB_EXECUTION_LOG
-- ----------------------------
DROP TABLE IF EXISTS `JOB_EXECUTION_LOG`;
CREATE TABLE `JOB_EXECUTION_LOG` (
  `id` varchar(40) NOT NULL,
  `job_name` varchar(100) NOT NULL,
  `task_id` varchar(255) NOT NULL,
  `hostname` varchar(255) NOT NULL,
  `ip` varchar(50) NOT NULL,
  `sharding_item` int(11) NOT NULL,
  `execution_source` varchar(20) NOT NULL,
  `failure_cause` varchar(4000) DEFAULT NULL,
  `is_success` int(11) NOT NULL,
  `start_time` timestamp NULL DEFAULT NULL,
  `complete_time` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务表';

-- ----------------------------
-- Records of JOB_EXECUTION_LOG
-- ----------------------------
INSERT INTO `JOB_EXECUTION_LOG` VALUES ('fff6f494-82b6-418c-9f6a-5e864c11680d', 'com.paascloud.provider.job.dataflow.HandleSendingMessageJob', 'com.paascloud.provider.job.dataflow.HandleSendingMessageJob@-@0@-@READY@-@192.168.32.191@-@16816', 'passcloud-pc', '192.168.32.191', '0', 'NORMAL_TRIGGER', null, '1', '2018-02-26 14:22:30', '2018-02-26 14:22:30');

-- ----------------------------
-- Table structure for JOB_STATUS_TRACE_LOG
-- ----------------------------
DROP TABLE IF EXISTS `JOB_STATUS_TRACE_LOG`;
CREATE TABLE `JOB_STATUS_TRACE_LOG` (
  `id` varchar(40) NOT NULL,
  `job_name` varchar(100) NOT NULL,
  `original_task_id` varchar(255) NOT NULL,
  `task_id` varchar(255) NOT NULL,
  `slave_id` varchar(50) NOT NULL,
  `source` varchar(50) NOT NULL,
  `execution_type` varchar(20) NOT NULL,
  `sharding_item` varchar(100) NOT NULL,
  `state` varchar(20) NOT NULL,
  `message` varchar(4000) DEFAULT NULL,
  `creation_time` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `TASK_ID_STATE_INDEX` (`task_id`,`state`)
) ROW_FORMAT=DYNAMIC ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of JOB_STATUS_TRACE_LOG
-- ----------------------------
INSERT INTO `JOB_STATUS_TRACE_LOG` VALUES ('fffe3de2-3c08-4f10-80cd-4364551663ed', 'com.paascloud.provider.job.dataflow.HandleSendingMessageJob', '', 'com.paascloud.provider.job.dataflow.HandleSendingMessageJob@-@0@-@READY@-@192.168.1.13@-@20436', '192.168.1.13', 'LITE_EXECUTOR', 'READY', '[0]', 'TASK_STAGING', 'Job \'com.paascloud.provider.job.dataflow.HandleSendingMessageJob\' execute begin.', '2018-02-25 23:10:30');

-- ----------------------------
-- Table structure for pc_tpc_job_task
-- ----------------------------
DROP TABLE IF EXISTS `pc_tpc_job_task`;
CREATE TABLE `pc_tpc_job_task` (
  `id` bigint(20) NOT NULL COMMENT '主键',
  `version` int(11) DEFAULT '0',
  `ref_no` varchar(32) CHARACTER SET utf8 DEFAULT '' COMMENT '关联业务单号',
  `task_type` varchar(30) CHARACTER SET utf8 DEFAULT '' COMMENT '业务类型',
  `task_data` longtext CHARACTER SET utf8 COMMENT '任务数据',
  `task_exe_count` int(11) DEFAULT '0' COMMENT '执行次数',
  `dead` int(11) DEFAULT '0' COMMENT '是否死亡 0 - 活着; 1-死亡',
  `status` int(11) DEFAULT '0' COMMENT '状态',
  `exe_instance_ip` varchar(100) CHARACTER SET utf8 DEFAULT NULL COMMENT '执行实例IP',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  `exe_time` int(11) DEFAULT NULL COMMENT '执行时间',
  `yn` int(255) DEFAULT '0' COMMENT '删除标识',
  PRIMARY KEY (`id`),
  KEY `idx_REF_NO` (`ref_no`) USING BTREE,
  KEY `index_CREATE_TIME` (`create_time`) USING BTREE,
  KEY `idx_TASKTYPE_STATUS_YN` (`task_type`,`status`,`yn`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='worker任务表';

-- ----------------------------
-- Records of pc_tpc_job_task
-- ----------------------------

-- ----------------------------
-- Table structure for pc_tpc_mq_confirm
-- ----------------------------
DROP TABLE IF EXISTS `pc_tpc_mq_confirm`;
CREATE TABLE `pc_tpc_mq_confirm` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `version` int(11) DEFAULT '0' COMMENT '版本号',
  `message_id` bigint(20) DEFAULT NULL COMMENT '任务ID',
  `message_key` varchar(200) CHARACTER SET utf8 DEFAULT '' COMMENT '消息唯一标识',
  `consumer_code` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '消费者组编码',
  `consume_count` int(11) DEFAULT '0' COMMENT '消费的数次',
  `status` int(255) DEFAULT '10' COMMENT '状态, 10 - 未确认 ; 20 - 已确认; 30 已消费',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_message_key` (`message_key`) USING BTREE,
  KEY `idx_created_time` (`created_time`) USING BTREE,
  KEY `idx_update_time` (`update_time`) USING BTREE,
  KEY `idx_task_id` (`message_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='订阅者状态确认表';

-- ----------------------------
-- Records of pc_tpc_mq_confirm
-- ----------------------------

-- ----------------------------
-- Table structure for pc_tpc_mq_consumer
-- ----------------------------
DROP TABLE IF EXISTS `pc_tpc_mq_consumer`;
CREATE TABLE `pc_tpc_mq_consumer` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `version` int(11) DEFAULT '0' COMMENT '版本号',
  `aplication_name` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '微服务名称',
  `consumer_code` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '消费者编码',
  `consumer_name` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '消费者名称',
  `status` int(255) DEFAULT '10' COMMENT '状态, 10生效,20,失效',
  `remark` varchar(255) CHARACTER SET utf8 DEFAULT '' COMMENT '备注',
  `creator` varchar(20) CHARACTER SET utf8 DEFAULT NULL COMMENT '创建人',
  `creator_id` bigint(20) DEFAULT NULL COMMENT '创建人ID',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `last_operator` varchar(20) CHARACTER SET utf8 DEFAULT NULL COMMENT '最近操作人',
  `last_operator_id` bigint(20) DEFAULT NULL COMMENT '最后操作人ID',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COMMENT='消费者表';

-- ----------------------------
-- Records of pc_tpc_mq_consumer
-- ----------------------------
INSERT INTO `pc_tpc_mq_consumer` VALUES ('1', '1', 'paascloud-provider-uac', 'CID_UAC', '用户中心', '20', '', '超级管理员', '1', '2018-01-20 11:17:10', '超级管理员', '1', '2018-02-02 23:37:26');
INSERT INTO `pc_tpc_mq_consumer` VALUES ('2', '1', 'paascloud-provider-mdc', 'CID_MDC', '数据中心', '10', '', '超级管理员', '1', '2018-01-20 11:17:10', '超级管理员', '1', '2018-02-02 23:37:39');
INSERT INTO `pc_tpc_mq_consumer` VALUES ('3', '1', 'paascloud-provider-omc', 'CID_OMC', '订单中心', '20', '', '超级管理员', '1', '2018-01-20 11:17:10', '超级管理员1', '1', '2018-01-20 11:17:10');
INSERT INTO `pc_tpc_mq_consumer` VALUES ('4', '1', 'paascloud-provider-opc', 'CID_OPC', '对接中心', '10', '', '超级管理员', '1', '2018-01-20 11:17:10', '超级管理员', '1', '2018-02-02 23:30:41');

-- ----------------------------
-- Table structure for pc_tpc_mq_message
-- ----------------------------
DROP TABLE IF EXISTS `pc_tpc_mq_message`;
CREATE TABLE `pc_tpc_mq_message` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `version` int(11) DEFAULT '0' COMMENT '版本号',
  `message_key` varchar(200) CHARACTER SET utf8 DEFAULT '' COMMENT '消息key',
  `message_topic` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT 'topic',
  `message_tag` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT 'tag',
  `message_body` longtext CHARACTER SET utf8 COMMENT '消息内容',
  `message_type` int(11) DEFAULT '10' COMMENT '消息类型: 10 - 有序消息 ; 20 - 无序消息',
  `producer_group` varchar(20) CHARACTER SET utf8 DEFAULT '' COMMENT '生产者PID',
  `delay_level` int(11) DEFAULT '0' COMMENT '延时级别 1s 5s 10s 30s 1m 2m 3m 4m 5m 6m 7m 8m 9m 10m 20m 30m 1h 2h',
  `order_type` int(11) DEFAULT '0' COMMENT '顺序类型 0有序 1无序',
  `message_status` int(11) DEFAULT '10' COMMENT '消息状态',
  `task_status` int(11) DEFAULT '0' COMMENT '状态',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  `resend_times` int(11) DEFAULT '0' COMMENT '重发次数',
  `dead` int(11) DEFAULT '0' COMMENT '是否死亡 0 - 活着; 1-死亡',
  `next_exe_time` int(11) DEFAULT NULL COMMENT '执行时间',
  `yn` int(11) DEFAULT '0' COMMENT '是否删除 -0 未删除 -1 已删除',
  `creator` varchar(20) CHARACTER SET utf8 DEFAULT NULL COMMENT '创建人',
  `creator_id` bigint(20) DEFAULT NULL COMMENT '创建人ID',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `last_operator` varchar(20) CHARACTER SET utf8 DEFAULT NULL COMMENT '最近操作人',
  `last_operator_id` bigint(20) DEFAULT NULL COMMENT '最后操作人ID',
  PRIMARY KEY (`id`),
  KEY `idx_message_key` (`message_key`) USING BTREE,
  KEY `idx_created_time` (`created_time`) USING BTREE,
  KEY `idx_update_time` (`update_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='可靠消息表';

-- ----------------------------
-- Records of pc_tpc_mq_message
-- ----------------------------

-- ----------------------------
-- Table structure for pc_tpc_mq_producer
-- ----------------------------
DROP TABLE IF EXISTS `pc_tpc_mq_producer`;
CREATE TABLE `pc_tpc_mq_producer` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `version` int(11) DEFAULT '0' COMMENT '版本号',
  `aplication_name` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '微服务名称',
  `producer_code` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '城市编码',
  `producer_name` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '区域编码',
  `query_message_url` varchar(255) CHARACTER SET utf8 DEFAULT '' COMMENT '提供查询对账的地址',
  `status` int(255) DEFAULT '10' COMMENT '状态, 10生效,20,失效',
  `remark` varchar(255) CHARACTER SET utf8 DEFAULT '' COMMENT '备注',
  `creator` varchar(20) CHARACTER SET utf8 DEFAULT NULL COMMENT '创建人',
  `creator_id` bigint(20) DEFAULT NULL COMMENT '创建人ID',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `last_operator` varchar(20) CHARACTER SET utf8 DEFAULT NULL COMMENT '最近操作人',
  `last_operator_id` bigint(20) DEFAULT NULL COMMENT '最后操作人ID',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COMMENT='生产者表';

-- ----------------------------
-- Records of pc_tpc_mq_producer
-- ----------------------------
INSERT INTO `pc_tpc_mq_producer` VALUES ('1', '1', 'paascloud-provider-uac', 'PID_UAC', '用户中心', '', '10', '', '超级管理员', '1', '2018-01-20 11:17:10', '超级管理员', '1', '2018-02-02 23:27:33');
INSERT INTO `pc_tpc_mq_producer` VALUES ('2', '1', 'paascloud-provider-mdc', 'PID_MDC', '数据中心', '', '10', '', '超级管理员', '1', '2018-01-20 11:17:10', '超级管理员', '1', '2018-01-21 12:55:04');
INSERT INTO `pc_tpc_mq_producer` VALUES ('3', '1', 'paascloud-provider-omc', 'PID_OMC', '订单中心', '', '20', '', '超级管理员', '1', '2018-01-20 11:17:10', '超级管理员', '1', '2018-01-21 12:55:02');
INSERT INTO `pc_tpc_mq_producer` VALUES ('4', '1', 'paascloud-provider-opc', 'PID_OPC', '对接中心', '', '20', '', '超级管理员', '1', '2018-01-20 11:17:10', '超级管理员1', '1', '2018-01-20 11:17:10');
INSERT INTO `pc_tpc_mq_producer` VALUES ('5', '1', 'paascloud-provider-tpc', 'PID_TPC', '任务中心', '', '10', '', '超级管理员', '1', '2018-01-20 11:17:10', '超级管理员1', '1', '2018-01-20 11:17:10');

-- ----------------------------
-- Table structure for pc_tpc_mq_publish
-- ----------------------------
DROP TABLE IF EXISTS `pc_tpc_mq_publish`;
CREATE TABLE `pc_tpc_mq_publish` (
  `producer_id` bigint(20) NOT NULL COMMENT '生产者ID',
  `topic_id` bigint(20) NOT NULL COMMENT 'TOPIC_ID',
  PRIMARY KEY (`producer_id`,`topic_id`),
  KEY `FKfe9od4909llybiub42s3ifvcl` (`topic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发布关系表';

-- ----------------------------
-- Records of pc_tpc_mq_publish
-- ----------------------------
INSERT INTO `pc_tpc_mq_publish` VALUES ('1', '1');
INSERT INTO `pc_tpc_mq_publish` VALUES ('1', '2');

-- ----------------------------
-- Table structure for pc_tpc_mq_resend_log
-- ----------------------------
DROP TABLE IF EXISTS `pc_tpc_mq_resend_log`;
CREATE TABLE `pc_tpc_mq_resend_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `version` int(11) DEFAULT '0' COMMENT '版本号',
  `message_id` bigint(20) DEFAULT NULL COMMENT '任务id',
  `message_key` int(11) DEFAULT '10' COMMENT '消息唯一标识',
  `creator` varchar(20) CHARACTER SET utf8 DEFAULT '' COMMENT '创建人',
  `creator_id` bigint(20) DEFAULT NULL COMMENT '创建人ID',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_message_key` (`message_key`) USING BTREE,
  KEY `idx_task_id` (`message_id`) USING BTREE,
  KEY `idx_created_time` (`created_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='重发日志表';

-- ----------------------------
-- Records of pc_tpc_mq_resend_log
-- ----------------------------

-- ----------------------------
-- Table structure for pc_tpc_mq_subscribe
-- ----------------------------
DROP TABLE IF EXISTS `pc_tpc_mq_subscribe`;
CREATE TABLE `pc_tpc_mq_subscribe` (
  `id` bigint(20) NOT NULL COMMENT 'ID',
  `consumer_id` bigint(20) NOT NULL COMMENT '消费者ID',
  `consumer_code` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '消费者组',
  `topic_id` bigint(20) NOT NULL COMMENT 'TOPIC_ID',
  `topic_code` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '主题编码',
  PRIMARY KEY (`id`),
  KEY `FKfe9od4909llybiub42s3ifvcl` (`topic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订阅关系表';

-- ----------------------------
-- Records of pc_tpc_mq_subscribe
-- ----------------------------
INSERT INTO `pc_tpc_mq_subscribe` VALUES ('1', '4', 'CID_OPC', '1', 'SEND_SMS_TOPIC');
INSERT INTO `pc_tpc_mq_subscribe` VALUES ('2', '4', 'CID_OPC', '2', 'SEND_EMAIL_TOPIC');
INSERT INTO `pc_tpc_mq_subscribe` VALUES ('3', '4', 'CID_OPC', '3', 'TPC_TOPIC');
INSERT INTO `pc_tpc_mq_subscribe` VALUES ('4', '1', 'CID_UAC', '3', 'TPC_TOPIC');
INSERT INTO `pc_tpc_mq_subscribe` VALUES ('5', '1', 'CID_OPC', '4', 'MDC_TOPIC');

-- ----------------------------
-- Table structure for pc_tpc_mq_subscribe_tag
-- ----------------------------
DROP TABLE IF EXISTS `pc_tpc_mq_subscribe_tag`;
CREATE TABLE `pc_tpc_mq_subscribe_tag` (
  `subscribe_id` bigint(20) NOT NULL COMMENT '消费者ID',
  `tag_id` bigint(20) NOT NULL COMMENT 'TAG_ID',
  PRIMARY KEY (`subscribe_id`,`tag_id`),
  KEY `FKfe9od4909llybiub42s3ifvcl` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消费者和TAG中间表';

-- ----------------------------
-- Records of pc_tpc_mq_subscribe_tag
-- ----------------------------
INSERT INTO `pc_tpc_mq_subscribe_tag` VALUES ('1', '1');
INSERT INTO `pc_tpc_mq_subscribe_tag` VALUES ('1', '2');
INSERT INTO `pc_tpc_mq_subscribe_tag` VALUES ('1', '3');
INSERT INTO `pc_tpc_mq_subscribe_tag` VALUES ('2', '4');
INSERT INTO `pc_tpc_mq_subscribe_tag` VALUES ('2', '5');
INSERT INTO `pc_tpc_mq_subscribe_tag` VALUES ('2', '6');
INSERT INTO `pc_tpc_mq_subscribe_tag` VALUES ('3', '7');
INSERT INTO `pc_tpc_mq_subscribe_tag` VALUES ('4', '8');
INSERT INTO `pc_tpc_mq_subscribe_tag` VALUES ('5', '9');
INSERT INTO `pc_tpc_mq_subscribe_tag` VALUES ('5', '10');

-- ----------------------------
-- Table structure for pc_tpc_mq_tag
-- ----------------------------
DROP TABLE IF EXISTS `pc_tpc_mq_tag`;
CREATE TABLE `pc_tpc_mq_tag` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `version` int(11) DEFAULT '0' COMMENT '版本号',
  `topic_id` bigint(20) DEFAULT NULL COMMENT '主题ID',
  `tag_code` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '城市编码',
  `tag_name` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '区域编码',
  `status` int(255) DEFAULT '10' COMMENT '状态, 10生效,20,失效',
  `remark` varchar(255) CHARACTER SET utf8 DEFAULT '' COMMENT '备注',
  `creator` varchar(20) CHARACTER SET utf8 DEFAULT NULL COMMENT '创建人',
  `creator_id` bigint(20) DEFAULT NULL COMMENT '创建人ID',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `last_operator` varchar(20) CHARACTER SET utf8 DEFAULT NULL COMMENT '最近操作人',
  `last_operator_id` bigint(20) DEFAULT NULL COMMENT '最后操作人ID',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COMMENT='MQ主题的标签表';

-- ----------------------------
-- Records of pc_tpc_mq_tag
-- ----------------------------
INSERT INTO `pc_tpc_mq_tag` VALUES ('1', '0', '1', 'REGISTER_USER_AUTH_CODE', '注册获取验证码', '10', '', '超级管理员', '1', '2018-01-20 11:38:39', '超级管理员', '1', '2018-02-02 23:38:59');
INSERT INTO `pc_tpc_mq_tag` VALUES ('2', '0', '1', 'MODIFY_PASSWORD_AUTH_CODE', '修改密码获取验证码', '10', '', '超级管理员', '1', '2018-01-20 11:38:39', '超级管理员', '1', '2018-02-02 23:38:57');
INSERT INTO `pc_tpc_mq_tag` VALUES ('3', '0', '1', 'FORGOT_PASSWORD_AUTH_CODE', '忘记密码获取验证码', '10', '', '超级管理员', '1', '2018-01-20 11:38:39', '超级管理员', '1', '2018-02-02 23:39:01');
INSERT INTO `pc_tpc_mq_tag` VALUES ('4', '0', '2', 'ACTIVE_USER', '提示激活用户', '10', '', '超级管理员', '1', '2018-01-20 11:38:39', '超级管理员', '1', '2018-02-02 23:39:03');
INSERT INTO `pc_tpc_mq_tag` VALUES ('5', '0', '2', 'ACTIVE_USER_SUCCESS', '激活用户成功', '10', '', '超级管理员', '1', '2018-01-20 11:38:39', '超级管理员', '1', '2018-02-02 23:39:05');
INSERT INTO `pc_tpc_mq_tag` VALUES ('6', '0', '2', 'RESET_LOGIN_PWD', '重置密码成功', '10', '', '超级管理员', '1', '2018-01-20 11:38:39', '超级管理员', '1', '2018-02-02 23:39:07');
INSERT INTO `pc_tpc_mq_tag` VALUES ('7', '0', '3', 'DELETE_PRODUCER_MESSAGE', '删除生产者历史消息', '10', '', '超级管理员', '1', '2018-01-20 11:38:39', '超级管理员', '1', '2018-02-02 23:39:07');
INSERT INTO `pc_tpc_mq_tag` VALUES ('8', '0', '3', 'DELETE_CONSUMER_MESSAGE', '删除消费者历史消息', '10', '', '超级管理员', '1', '2018-01-20 11:38:39', '超级管理员', '1', '2018-02-02 23:39:07');
INSERT INTO `pc_tpc_mq_tag` VALUES ('9', '0', '4', 'UPDATE_ATTACHMENT', '更新附件信息', '10', '', '超级管理员', '1', '2018-01-20 11:38:39', '超级管理员', '1', '2018-02-02 23:39:07');
INSERT INTO `pc_tpc_mq_tag` VALUES ('10', '0', '4', 'DELETE_ATTACHMENT', '删除附件信息', '10', '', '超级管理员', '1', '2018-01-20 11:38:39', '超级管理员', '1', '2018-02-02 23:39:07');

-- ----------------------------
-- Table structure for pc_tpc_mq_topic
-- ----------------------------
DROP TABLE IF EXISTS `pc_tpc_mq_topic`;
CREATE TABLE `pc_tpc_mq_topic` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `version` int(11) DEFAULT '0' COMMENT '版本号',
  `producer_id` bigint(20) DEFAULT NULL COMMENT '生产者ID',
  `topic_code` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '城市编码',
  `topic_name` varchar(50) CHARACTER SET utf8 DEFAULT '' COMMENT '区域编码',
  `mq_type` int(11) NOT NULL DEFAULT '10' COMMENT 'MQ类型, 10 rocketmq 20 kafka',
  `msg_type` int(11) NOT NULL DEFAULT '10' COMMENT '消息类型, 10 无序消息, 20 无序消息',
  `status` int(255) DEFAULT '10' COMMENT '状态, 10生效,20,失效',
  `remarks` varchar(255) CHARACTER SET utf8 DEFAULT '' COMMENT '备注',
  `creator` varchar(20) CHARACTER SET utf8 DEFAULT NULL COMMENT '创建人',
  `creator_id` bigint(20) DEFAULT NULL COMMENT '创建人ID',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `last_operator` varchar(20) CHARACTER SET utf8 DEFAULT NULL COMMENT '最近操作人',
  `last_operator_id` bigint(20) DEFAULT NULL COMMENT '最后操作人ID',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COMMENT='MQ主题表';

-- ----------------------------
-- Records of pc_tpc_mq_topic
-- ----------------------------
INSERT INTO `pc_tpc_mq_topic` VALUES ('1', '0', null, 'SEND_SMS_TOPIC', '发送短信验证码', '10', '10', '10', '', '超级管理员', '1', '2018-01-17 23:21:42', '超级管理员', '1', '2018-02-02 23:31:32');
INSERT INTO `pc_tpc_mq_topic` VALUES ('2', '0', null, 'SEND_EMAIL_TOPIC', '发送邮件', '10', '10', '10', '', '超级管理员', '1', '2018-01-17 23:21:42', '超级管理员', '1', '2018-01-21 10:43:11');
INSERT INTO `pc_tpc_mq_topic` VALUES ('3', '0', null, 'TPC_TOPIC', '任务中心TOPIC', '10', '10', '10', '', '超级管理员', '1', '2018-01-17 23:21:42', '超级管理员', '1', '2018-01-21 10:43:11');
INSERT INTO `pc_tpc_mq_topic` VALUES ('4', '0', null, 'MDC_TOPIC', '数据中心TOPIC', '10', '10', '10', '', '超级管理员', '1', '2018-01-17 23:21:42', '超级管理员', '1', '2018-01-21 10:43:11');
