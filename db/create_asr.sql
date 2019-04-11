--
-- Table structure for table `callhistory`
--

DROP TABLE IF EXISTS `callhistory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `callhistory` (
  `callid` varchar(32) NOT NULL,
  `userid` varchar(32) NOT NULL,
  `robotid` varchar(32) NOT NULL,  
  `caller` varchar(32),
  `callee` varchar(32) NOT NULL, 
  `gateway` varchar(32),
  `createtime` int(10) DEFAULT NULL,
  `answertime` int(10) DEFAULT NULL,
  `hangtime` int(10) DEFAULT NULL,
  `callduration` int(10) DEFAULT NULL,
  `hangcause` int(10) DEFAULT NULL,
  PRIMARY KEY (`callid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;  
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `calldialog`
--

DROP TABLE IF EXISTS `calldialog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `calldialog` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `callid` varchar(32) NOT NULL,
  `dialogseq` int(10) NOT NULL,
  `playfile` varchar(32),  
  `detected` varchar(512),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;  
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `callrecord`
--

DROP TABLE IF EXISTS `callrecord`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `callrecord` (
  `callid` varchar(32) NOT NULL,
  `recordfile` varchar(32) NOT NULL,
  `recordhost` varchar(32) NOT NULL,  
  `recordlen` int(10) NOT NULL,
  `cloudlk` varchar(128),
  PRIMARY KEY (`callid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;  
/*!40101 SET character_set_client = @saved_cs_client */;

