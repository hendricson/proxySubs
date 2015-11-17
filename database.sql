CREATE TABLE IF NOT EXISTS `proxies1` (
  `proxy` varchar(50) NOT NULL,
  `failed` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`proxy`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;