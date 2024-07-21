// 国内DNS服务器
const domesticNameservers = ["https://107834.alidns.com/dns-query"];
// 国外DNS服务器
const foreignNameservers = [
  "https://1.1.1.1/dns-query",
  "https://dns.google/dns-query",
];

const fallbackFilter = {
  geoip: true,
  geoipCode: "CN",
  ipcidr: ["240.0.0.0/4"],
  domain: [
    "+.lajichang.xyz",
    "+.lajichang.eu",
    "+.lajic.eu",
    "+.198466.xyz",
    "+.alibabaapi6.com",
    "+.19842333.xyz",
    "+.198477.xyz",
    "+.198488.xyz",
    "+.ipv6boy.xyz",
    "+.ipv6boy.com",
    "+.ipv6boy.top",
    "+.google.com",
    "+.facebook.com",
    "+.twitter.com",
    "+.tiktokv.com",
    "+.bytedance.map.fastly",
    "+.tiktok.com",
    "+.youtube.com",
    "+.xn--ngstr-lra8j.com",
    "+.google.cn",
    "+.googleapis.cn",
    "+.googleapis.com",
    "+.gvt1.com",
  ],
};
// DNS配置
const dnsConfig = {
  enable: true,
  listen: "127.0.0.1:53",
  ipv6: true,
  "use-system-hosts": true,
  "cache-algorithm": "arc",
  "enhanced-mode": "fake-ip",
  "fake-ip-range": "198.18.0.1/16",
  "fake-ip-filter": [
    // 本地主机/设备
    "+.lan",
    "+.local",
    // Windows网络出现小地球图标
    "+.msftconnecttest.com",
    "+.msftncsi.com",
    // QQ快速登录检测失败
    "localhost.ptlogin2.qq.com",
    "localhost.sec.qq.com",
    // 微信快速登录检测失败
    "localhost.work.weixin.qq.com",
  ],
  "default-nameserver": ["223.5.5.5", "119.29.29.29"],
  nameserver: [...domesticNameservers, ...foreignNameservers],
  "proxy-server-nameserver": [
    ...domesticNameservers,
    ...foreignNameservers,
  ],
  "nameserver-policy": {
    "geosite:private,cn,geolocation-cn": domesticNameservers,
    "geosite:google,youtube,telegram,gfw,geolocation-!cn":
      foreignNameservers,
  },
  fallbackFilter: fallbackFilter,
};

// 规则集通用配置
const ruleProviderCommon = {
  type: "http",
  format: "yaml",
  interval: 86400,
};
// 规则集配置
const ruleProviders = {
  reject: {
    ...ruleProviderCommon,
    behavior: "domain",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/reject.txt",
    path: "./ruleset/loyalsoldier/reject.yaml",
  },
  icloud: {
    ...ruleProviderCommon,
    behavior: "domain",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/icloud.txt",
    path: "./ruleset/loyalsoldier/icloud.yaml",
  },
  apple: {
    ...ruleProviderCommon,
    behavior: "domain",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/apple.txt",
    path: "./ruleset/loyalsoldier/apple.yaml",
  },
  google: {
    ...ruleProviderCommon,
    behavior: "domain",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/google.txt",
    path: "./ruleset/loyalsoldier/google.yaml",
  },
  proxy: {
    ...ruleProviderCommon,
    behavior: "domain",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/proxy.txt",
    path: "./ruleset/loyalsoldier/proxy.yaml",
  },
  direct: {
    ...ruleProviderCommon,
    behavior: "domain",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/direct.txt",
    path: "./ruleset/loyalsoldier/direct.yaml",
  },
  private: {
    ...ruleProviderCommon,
    behavior: "domain",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/private.txt",
    path: "./ruleset/loyalsoldier/private.yaml",
  },
  gfw: {
    ...ruleProviderCommon,
    behavior: "domain",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/gfw.txt",
    path: "./ruleset/loyalsoldier/gfw.yaml",
  },
  "tld-not-cn": {
    ...ruleProviderCommon,
    behavior: "domain",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/tld-not-cn.txt",
    path: "./ruleset/loyalsoldier/tld-not-cn.yaml",
  },
  telegramcidr: {
    ...ruleProviderCommon,
    behavior: "ipcidr",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/telegramcidr.txt",
    path: "./ruleset/loyalsoldier/telegramcidr.yaml",
  },
  cncidr: {
    ...ruleProviderCommon,
    behavior: "ipcidr",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/cncidr.txt",
    path: "./ruleset/loyalsoldier/cncidr.yaml",
  },
  lancidr: {
    ...ruleProviderCommon,
    behavior: "ipcidr",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/lancidr.txt",
    path: "./ruleset/loyalsoldier/lancidr.yaml",
  },
  applications: {
    ...ruleProviderCommon,
    behavior: "classical",
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/applications.txt",
    path: "./ruleset/loyalsoldier/applications.yaml",
  },
  openai: {
    ...ruleProviderCommon,
    behavior: "classical",
    url: "https://fastly.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/OpenAI/OpenAI.yaml",
    path: "./ruleset/blackmatrix7/openai.yaml",
  },
};
// 规则
const rules = [
  // 自定义规则
  "DOMAIN-SUFFIX,googleapis.cn,节点选择", // Google服务
  "DOMAIN-SUFFIX,gstatic.com,节点选择", // Google静态资源
  "DOMAIN-SUFFIX,xn--ngstr-lra8j.com,节点选择", // Google Play下载服务
  "RULE-SET,applications,DIRECT",
  "RULE-SET,private,DIRECT",
  "RULE-SET,reject,广告过滤",
  "RULE-SET,icloud,节点选择",
  "RULE-SET,apple,DIRECT",
  "RULE-SET,google,节点选择",
  "RULE-SET,proxy,节点选择",
  "RULE-SET,gfw,节点选择",
  "RULE-SET,tld-not-cn,节点选择",
  "RULE-SET,direct,DIRECT",
  "RULE-SET,lancidr,DIRECT,no-resolve",
  "RULE-SET,cncidr,DIRECT,no-resolve",
  "RULE-SET,telegramcidr,节点选择,no-resolve",

  "DOMAIN-SUFFIX,github.com, 节点选择",
  "DOMAIN-SUFFIX,youtube.com, 节点选择",
  "DOMAIN-SUFFIX,edaplayground.com, 节点选择",
  "DOMAIN-SUFFIX,docker.io, 节点选择",
  "DOMAIN,gstatic.com,DIRECT",
  "DOMAIN-SUFFIX,acm.org,DIRECT",
  "DOMAIN-SUFFIX,ieee.org,DIRECT",
  "DOMAIN,hdlbits.01xz.net, 节点选择",
  "DOMAIN-SUFFIX,steamcontent.com,DIRECT",
  "DOMAIN-SUFFIX,steamstatic.com,DIRECT",
  "DOMAIN-SUFFIX,steamserver.net,DIRECT",
  "DOMAIN-SUFFIX,test.steampowered.com,DIRECT",
  "DOMAIN-SUFFIX,api.steampowered.com,DIRECT",
  "DOMAIN-SUFFIX,rmbgame.net,DIRECT",
  "DOMAIN,clash.razord.top,DIRECT",
  "DOMAIN,local.adguard.org,DIRECT",
  "DOMAIN,yacd.haishan.me,DIRECT",
  "DOMAIN,injections.adguard.org, 节点选择",
  "DOMAIN,akamaized.net, 节点选择",
  "DOMAIN-SUFFIX,hust.edu.cn,DIRECT",
  "DOMAIN-SUFFIX,aka.ms,节点选择",
  "DOMAIN-SUFFIX,bing.com,节点选择",
  "DOMAIN-SUFFIX,typora.io,DIRECT",
  "GEOIP,LAN,DIRECT,no-resolve",
  "GEOIP,CN,DIRECT,no-resolve",
  "MATCH, 漏网之鱼",
];
// 代理组通用配置
const groupBaseOption = {
  interval: 300,
  timeout: 3000,
  url: "https://www.google.com/generate_204",
  lazy: true,
  "max-failed-times": 3,
  hidden: false,
};

// 程序入口
function main(config) {
  const proxyCount = config?.proxies?.length ?? 0;
  const proxyProviderCount =
    typeof config?.["proxy-providers"] === "object"
      ? Object.keys(config["proxy-providers"]).length
      : 0;
  if (proxyCount === 0 && proxyProviderCount === 0) {
    throw new Error("配置文件中未找到任何代理");
  }

  // 覆盖原配置中DNS配置
  config["dns"] = dnsConfig;
  const proxies = config["proxies"];
  const pro = proxies.map((item) => item.name);

  // 覆盖原配置中的代理组
  config["proxy-groups"] = [
    {
      ...groupBaseOption,
      name: "节点选择",
      type: "select",
      proxies: ["DIRECT"].concat(...pro),
      icon: "https://fastly.jsdelivr.net/gh/clash-verge-rev/clash-verge-rev.github.io@main/docs/assets/icons/adjust.svg",
    },
    {
      ...groupBaseOption,
      name: "广告过滤",
      type: "select",
      proxies: ["REJECT", "DIRECT", "节点选择"],
      icon: "https://fastly.jsdelivr.net/gh/clash-verge-rev/clash-verge-rev.github.io@main/docs/assets/icons/bug.svg",
    },
    {
      ...groupBaseOption,
      url: "https://chatgpt.com",
      "expected-status": "200",
      name: "ChatGPT",
      type: "select",
      proxies: ["DIRECT"].concat(...pro),
      filter:
        "AD|🇦🇩|AE|🇦🇪|AF|🇦🇫|AG|🇦🇬|AL|🇦🇱|AM|🇦🇲|AO|🇦🇴|AR|🇦🇷|AT|🇦🇹|AU|🇦🇺|AZ|🇦🇿|BA|🇧🇦|BB|🇧🇧|BD|🇧🇩|BE|🇧🇪|BF|🇧🇫|BG|🇧🇬|BH|🇧🇭|BI|🇧🇮|BJ|🇧🇯|BN|🇧🇳|BO|🇧🇴|BR|🇧🇷|BS|🇧🇸|BT|🇧🇹|BW|🇧🇼|BZ|🇧🇿|CA|🇨🇦|CD|🇨🇩|CF|🇨🇫|CG|🇨🇬|CH|🇨🇭|CI|🇨🇮|CL|🇨🇱|CM|🇨🇲|CO|🇨🇴|CR|🇨🇷|CV|🇨🇻|CY|🇨🇾|CZ|🇨🇿|DE|🇩🇪|DJ|🇩🇯|DK|🇩🇰|DM|🇩🇲|DO|🇩🇴|DZ|🇩🇿|EC|🇪🇨|EE|🇪🇪|EG|🇪🇬|ER|🇪🇷|ES|🇪🇸|ET|🇪🇹|FI|🇫🇮|FJ|🇫🇯|FM|🇫🇲|FR|🇫🇷|GA|🇬🇦|GB|🇬🇧|GD|🇬🇩|GE|🇬🇪|GH|🇬🇭|GM|🇬🇲|GN|🇬🇳|GQ|🇬🇶|GR|🇬🇷|GT|🇬🇹|GW|🇬🇼|GY|🇬🇾|HN|🇭🇳|HR|🇭🇷|HT|🇭🇹|HU|🇭🇺|ID|🇮🇩|IE|🇮🇪|IL|🇮🇱|IN|🇮🇳|IQ|🇮🇶|IS|🇮🇸|IT|🇮🇹|JM|🇯🇲|JO|🇯🇴|JP|🇯🇵|KE|🇰🇪|KG|🇰🇬|KH|🇰🇭|KI|🇰🇮|KM|🇰🇲|KN|🇰🇳|KR|🇰🇷|KW|🇰🇼|KZ|🇰🇿|LA|🇱🇦|LB|🇱🇧|LC|🇱🇨|LI|🇱🇮|LK|🇱🇰|LR|🇱🇷|LS|🇱🇸|LT|🇱🇹|LU|🇱🇺|LV|🇱🇻|LY|🇱🇾|MA|🇲🇦|MC|🇲🇨|MD|🇲🇩|ME|🇲🇪|MG|🇲🇬|MH|🇲🇭|MK|🇲🇰|ML|🇲🇱|MM|🇲🇲|MN|🇲🇳|MR|🇲🇷|MT|🇲🇹|MU|🇲🇺|MV|🇲🇻|MW|🇲🇼|MX|🇲🇽|MY|🇲🇾|MZ|🇲🇿|NA|🇳🇦|NE|🇳🇪|NG|🇳🇬|NI|🇳🇮|NL|🇳🇱|NO|🇳🇴|NP|🇳🇵|NR|🇳🇷|NZ|🇳🇿|OM|🇴🇲|PA|🇵🇦|PE|🇵🇪|PG|🇵🇬|PH|🇵🇭|PK|🇵🇰|PL|🇵🇱|PS|🇵🇸|PT|🇵🇹|PW|🇵🇼|PY|🇵🇾|QA|🇶🇦|RO|🇷🇴|RS|🇷🇸|RW|🇷🇼|SA|🇸🇦|SB|🇸🇧|SC|🇸🇨|SD|🇸🇩|SE|🇸🇪|SG|🇸🇬|SI|🇸🇮|SK|🇸🇰|SL|🇸🇱|SM|🇸🇲|SN|🇸🇳|SO|🇸🇴|SR|🇸🇷|SS|🇸🇸|ST|🇸🇹|SV|🇸🇻|SZ|🇸🇿|TD|🇹🇩|TG|🇹🇬|TH|🇹🇭|TJ|🇹🇯|TL|🇹🇱|TM|🇹🇲|TN|🇹🇳|TO|🇹🇴|TR|🇹🇷|TT|🇹🇹|TV|🇹🇻|TW|🇹🇼|TZ|🇹🇿|UA|🇺🇦|UG|🇺🇬|US|🇺🇸|UY|🇺🇾|UZ|🇺🇿|VA|🇻🇦|VC|🇻🇨|VN|🇻🇳|VU|🇻🇺|WS|🇼🇸|YE|🇾🇪|ZA|🇿🇦|ZM|🇿🇲|ZW|🇿🇼",
      icon: "https://fastly.jsdelivr.net/gh/clash-verge-rev/clash-verge-rev.github.io@main/docs/assets/icons/chatgpt.svg",
    },
    {
      ...groupBaseOption,
      name: "漏网之鱼",
      type: "select",
      proxies: ["DIRECT", "REJECT", "节点选择"],
      icon: "https://fastly.jsdelivr.net/gh/clash-verge-rev/clash-verge-rev.github.io@main/docs/assets/icons/fish.svg",
    },
  ];

  // 覆盖原配置中的规则
  config["rule-providers"] = ruleProviders;
  config["rules"] = rules;

  // 返回修改后的配置
  return config;
}
