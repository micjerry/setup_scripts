--
-- Table structure for table `scaccounts`
--

DROP TABLE IF EXISTS `scaccounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scaccounts` (
  `username` varchar(32) NOT NULL,
  `password` varchar(32) NOT NULL,
  `permits` varchar(32) DEFAULT NULL,
  `email` varchar(32) DEFAULT NULL,
  `mobilephone` varchar(32) DEFAULT NULL, 
  `forbid` int DEFAULT 0, 
  `createtime` timestamp DEFAULT NULL,
  PRIMARY KEY (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;  
/*!40101 SET character_set_client = @saved_cs_client */;
