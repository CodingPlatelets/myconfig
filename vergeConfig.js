// Define main function (script entry)
function main(content, profileName) {
  const isObject = (value) => {
    return value !== null && typeof value === "object";
  };

  const mergeConfig = (existingConfig, newConfig) => {
    if (!isObject(existingConfig)) {
      existingConfig = {};
    }
    if (!isObject(newConfig)) {
      return existingConfig;
    }
    return { ...existingConfig, ...newConfig };
  };

  // 国内DNS服务器
  const domesticNameservers = [
    "https://dns.alidns.com/dns-query", // 阿里云公共DNS
    "https://doh.pub/dns-query", // 腾讯DNSPod
  ];
  // 国外DNS服务器
  const foreignNameservers = [
    "https://1.1.1.1/dns-query", // Cloudflare(主)
    "https://1.0.0.1/dns-query", // Cloudflare(备)
    "https://208.67.222.222/dns-query", // OpenDNS(主)
    "https://208.67.220.220/dns-query", // OpenDNS(备)
    "https://194.242.2.2/dns-query", // Mullvad(主)
    "https://194.242.2.3/dns-query" // Mullvad(备)
  ];

  const dnsConfig = {
    "enable": true,
    "listen": "0.0.0.0:1053",
    "ipv6": true,
    "use-system-hosts": true,
    "cache-algorithm": "arc",
    "enhanced-mode": "fake-ip",
    "fake-ip-range": "198.18.0.1/16",
    "fake-ip-filter": [
      // 本地主机/设备
      "+.lan",
      "+.localdomain",
      "+.example",
      "+.invalid",
      "+.localhost",
      "+.test",
      "+.local",
      "+.home.arpa",

      // NTP服务
      "time.*.com",
      "time.*.gov",
      "time.*.edu.cn",
      "time.*.apple.com",
      "time-ios.apple.com",
      "time1.*.com",
      "time2.*.com",
      "time3.*.com",
      "time4.*.com",
      "time5.*.com",
      "time6.*.com",
      "time7.*.com",
      "ntp.*.com",
      "ntp1.*.com",
      "ntp2.*.com",
      "ntp3.*.com",
      "ntp4.*.com",
      "ntp5.*.com",
      "ntp6.*.com",
      "ntp7.*.com",
      "*.time.edu.cn",
      "*.ntp.org.cn",
      "+.pool.ntp.org",
      "time1.cloud.tencent.com",

      // 在线音乐服务
      "music.163.com",
      "*.music.163.com",
      "*.126.net",
      "musicapi.taihe.com",
      "music.taihe.com",
      "songsearch.kugou.com",
      "trackercdn.kugou.com",
      "*.kuwo.cn",
      "api-jooxtt.sanook.com",
      "api.joox.com",
      "joox.com",
      "y.qq.com",
      "*.y.qq.com",
      "streamoc.music.tc.qq.com",
      "mobileoc.music.tc.qq.com",
      "isure.stream.qqmusic.qq.com",
      "dl.stream.qqmusic.qq.com",
      "aqqmusic.tc.qq.com",
      "amobile.music.tc.qq.com",
      "*.xiami.com",
      "*.music.migu.cn",
      "music.migu.cn",

      // Windows网络连接检测
      "+.msftconnecttest.com",
      "+.msftncsi.com",
      "dns.msftncsi.com",
      "www.msftncsi.com",
      "www.msftconnecttest.com",

      // QQ/微信登录及相关服务
      "localhost.ptlogin2.qq.com",
      "localhost.sec.qq.com",
      "+.qq.com",
      "+.tencent.com",
      "localhost.work.weixin.qq.com",

      // 游戏服务
      "+.srv.nintendo.net",
      "*.n.n.srv.nintendo.net",
      "+.stun.playstation.net",
      "xbox.*.*.microsoft.com",
      "*.*.xboxlive.com",
      "xbox.*.microsoft.com",
      "xnotify.xboxlive.com",
      "+.battlenet.com.cn",
      "+.wotgame.cn",
      "+.wggames.cn",
      "+.wowsgame.cn",
      "+.wargaming.net",
      "*.square-enix.com",
      "*.finalfantasyxiv.com",
      "*.ffxiv.com",
      "*.ff14.sdo.com",
      "ff.dorado.sdo.com",

      // STUN服务
      "stun.*.*",
      "stun.*.*.*",
      "+.stun.*.*",
      "+.stun.*.*.*",
      "+.stun.*.*.*.*",
      "+.stun.*.*.*.*.*",

      // 路由器服务
      "heartbeat.belkin.com",
      "*.linksys.com",
      "*.linksyssmartwifi.com",
      "*.router.asus.com",

      // Apple 服务
      "mesu.apple.com",
      "swscan.apple.com",
      "swquery.apple.com",
      "swdownload.apple.com",
      "swcdn.apple.com",
      "swdist.apple.com",

      // Google 服务
      "lens.l.google.com",
      "stun.l.google.com",
      "na.b.g-tun.com",

      // 其他服务
      "proxy.golang.org",
      "+.nflxvideo.net",
      "*.mcdn.bilivideo.cn",
      "+.media.dssott.com",
      "shark007.net",
      "+.cmbchina.com",
      "+.cmbimg.com",
      "local.adguard.org",
      "+.sandai.net",
      "+.n0808.com",
      "services.googleapis.cn",
      "+.market.xiaomi.com",
      // Windows网络出现小地球图标
      "+.msftconnecttest.com",
      "+.msftncsi.com",
      // QQ快速登录检测失败
      "localhost.ptlogin2.qq.com",
      "localhost.sec.qq.com",
      // 微信快速登录检测失败
      "localhost.work.weixin.qq.com"
    ],
    "default-nameserver": ["223.5.5.5", "119.29.29.29", "1.1.1.1", "8.8.8.8"],
    "nameserver": [...domesticNameservers, ...foreignNameservers],
    "proxy-server-nameserver": [...domesticNameservers, ...foreignNameservers],
    "nameserver-policy": {
      "geosite:private,cn,geolocation-cn": domesticNameservers,
      "geosite:google,youtube,telegram,gfw,geolocation-!cn": foreignNameservers
    }
  };


  // GEO数据GitHub资源原始下载地址
  const rawGeoxURLs = {
    geoip:
      "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat",
    geosite:
      "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat",
    mmdb: "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country-lite.mmdb",
  };

  // 生成带有加速前缀的GEO数据资源对象,直接使用 github，不使用加速前缀
  const accelURLs = Object.fromEntries(
    Object.entries(rawGeoxURLs).map(([key, githubUrl]) => [
      key,
      `${githubUrl}`,
    ])
  );

  const otherOptions = {
    "unified-delay": true,
    "tcp-concurrent": true,
    profile: {
      "store-selected": true,
      "store-fake-ip": true,
    },
    sniffer: {
      enable: true,
      sniff: {
        TLS: {
          ports: [443, 8443],
        },
        HTTP: {
          ports: [80, "8080-8880"],
          "override-destination": true,
        },
      },
    },
    "geodata-mode": true,
    "geox-url": accelURLs,
  };
  const rules = [
    "DOMAIN-SUFFIX,github.com, 🔰 选择节点",
    "DOMAIN-SUFFIX,ipv6boy.xyz, 🔰 选择节点",
    "DOMAIN-SUFFIX,edaplayground.com, 🔰 选择节点",
    "DOMAIN-SUFFIX,docker.io, 🔰 选择节点",
    "DOMAIN-SUFFIX, byr.pt, DIRECT",
    "DOMAIN-SUFFIX, pandapt.net, DIRECT",
    "DOMAIN,gstatic.com,DIRECT",
    "DOMAIN-SUFFIX,acm.org,DIRECT",
    "DOMAIN-SUFFIX,ieee.org,DIRECT",
    "DOMAIN,hdlbits.01xz.net, 🔰 选择节点",
    "DOMAIN,sub.198477.xyz, 🔰 选择节点",
    "DOMAIN-SUFFIX,steamcontent.com,DIRECT",
    "DOMAIN-SUFFIX,steamstatic.com,DIRECT",
    "DOMAIN-SUFFIX,steamserver.net,DIRECT",
    "DOMAIN-SUFFIX,test.steampowered.com,DIRECT",
    "DOMAIN-SUFFIX,rmbgame.net,DIRECT",
    "RULE-SET,applications,DIRECT",
    "DOMAIN,clash.razord.top,DIRECT",
    "DOMAIN,local.adguard.org,DIRECT",
    "DOMAIN,yacd.haishan.me,DIRECT",
    "DOMAIN,injections.adguard.org, 🔰 选择节点",
    "DOMAIN,垃圾场珀.com, 🔰 选择节点",
    "DOMAIN,垃圾场六.com, 🔰 选择节点",
    "DOMAIN,akamaized.net, 🔰 选择节点",
    "RULE-SET,private,DIRECT",
    "RULE-SET,reject,🛑 广告拦截",
    "RULE-SET,icloud,DIRECT",
    "RULE-SET,apple,DIRECT",
    "DOMAIN-SUFFIX,hust.edu.cn,DIRECT",
    "RULE-SET,google,🔰 选择节点",
    "RULE-SET,tld-not-cn,🔰 选择节点",
    "DOMAIN-SUFFIX,aka.ms,🔰 选择节点",
    "DOMAIN-SUFFIX,bing.com,🔰 选择节点",
    "DOMAIN-SUFFIX,github.com,🔰 选择节点",
    "DOMAIN-SUFFIX,typora.io,🔰 选择节点",
    "RULE-SET,gfw,🔰 选择节点",
    "RULE-SET,greatfire,🔰 选择节点",
    "RULE-SET,telegramcidr,🔰 选择节点",
    "RULE-SET,lancidr,DIRECT,no-resolve",
    "RULE-SET,cncidr,DIRECT,no-resolve",
    "RULE-SET,direct,DIRECT",
    "RULE-SET,proxy,🔰 选择节点",
    "GEOIP,LAN,DIRECT,no-resolve",
    "GEOIP,CN,DIRECT,no-resolve",
    "MATCH,🐟 漏网之鱼",
  ];

  const ruleProviderCommon = {
    "type": "http",
    "format": "yaml",
    "interval": 86400
  };
  const rule_providers = {
    reject: {
      ...ruleProviderCommon,
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/reject.txt",
      path: "./ruleset/reject.yaml",
      interval: 86400,
    },
    icloud: {
      ...ruleProviderCommon,
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/icloud.txt",
      path: "./ruleset/icloud.yaml",
      interval: 86400,
    },
    apple: {
      ...ruleProviderCommon,
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/apple.txt",
      path: "./ruleset/apple.yaml",
      interval: 86400,
    },
    google: {
      ...ruleProviderCommon,
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/google.txt",
      path: "./ruleset/google.yaml",
      interval: 86400,
    },
    proxy: {
      ...ruleProviderCommon,
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/proxy.txt",
      path: "./ruleset/proxy.yaml",
      interval: 86400,
    },
    direct: {
      ...ruleProviderCommon,
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/direct.txt",
      path: "./ruleset/direct.yaml",
      interval: 86400,
    },
    private: {
      ...ruleProviderCommon,
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/private.txt",
      path: "./ruleset/private.yaml",
      interval: 86400,
    },
    gfw: {
      ...ruleProviderCommon,
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/gfw.txt",
      path: "./ruleset/gfw.yaml",
      interval: 86400,
    },
    greatfire: {
      ...ruleProviderCommon,
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/greatfire.txt",
      path: "./ruleset/greatfire.yaml",
      interval: 86400,
    },
    "tld-not-cn": {
      ...ruleProviderCommon,
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/tld-not-cn.txt",
      path: "./ruleset/tld-not-cn.yaml",
      interval: 86400,
    },
    telegramcidr: {
      ...ruleProviderCommon,
      behavior: "ipcidr",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/telegramcidr.txt",
      path: "./ruleset/telegramcidr.yaml",
      interval: 86400,
    },
    cncidr: {
      ...ruleProviderCommon,
      behavior: "ipcidr",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/cncidr.txt",
      path: "./ruleset/cncidr.yaml",
      interval: 86400,
    },
    lancidr: {
      ...ruleProviderCommon,
      behavior: "ipcidr",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/lancidr.txt",
      path: "./ruleset/lancidr.yaml",
      interval: 86400,
    },
    applications: {
      ...ruleProviderCommon,
      behavior: "classical",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/applications.txt",
      path: "./ruleset/applications.yaml",
      interval: 86400,
    },
  };

  const groupBaseOption = {
    interval: 300,
    timeout: 3000,
    url: "https://www.google.com/generate_204",
    lazy: true,
    "max-failed-times": 3,
    hidden: false,
  };

  const proxies = content["proxies"];
  const pro = proxies.map((item) => item.name);
  const groups = [
    {
      ...groupBaseOption,
      name: "🔰 选择节点",
      type: "select",
      proxies: ["DIRECT"].concat(...pro),
    },
    {
      ...groupBaseOption,
      name: "🛑 广告拦截",
      type: "select",
      proxies: ["DIRECT", "REJECT", "🔰 选择节点"],
    },
    {
      ...groupBaseOption,
      name: "🐟 漏网之鱼",
      type: "select",
      proxies: ["DIRECT", "REJECT", "🔰 选择节点"],
    },
  ];

  content["dns"] = dnsConfig;
  content["proxy-groups"] = groups;
  content["rule-providers"] = rule_providers;
  content["rules"] = rules;

  return { ...content, ...otherOptions };
}
