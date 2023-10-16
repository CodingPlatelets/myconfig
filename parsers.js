const _dns_default = ["223.5.5.5", "119.29.29.29"];
const _dns_nameserver = ["https://107834.alidns.com/dns-query"];
const _dns_fallback = [
  "tls://8.8.4.4:853",
  "https://1.1.1.1/dns-query",
  "tls://1.1.1.1:853",
  "tls://8.8.8.8:853",
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
const dns = {
  enable: true,
  listen: "127.0.0.1:53",
  enhancedMode: "fake-ip",
  fakeIpRange: "198.18.0.1/16",
  default_nameserver: _dns_default,
  nameserver: _dns_nameserver,
  fallback: _dns_fallback,
  fallbackFilter: fallbackFilter,
};

const rules = [
  "DOMAIN,gstatic.com,DIRECT",
  "RULE-SET,applications,DIRECT",
  "DOMAIN,clash.razord.top,DIRECT",
  "DOMAIN,local.adguard.org,DIRECT",
  "DOMAIN,yacd.haishan.me,DIRECT",
  "DOMAIN,injections.adguard.org, 🔰 选择节点",
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
  "RULE-SET,lancidr,DIRECT",
  "RULE-SET,cncidr,DIRECT",
  "GEOIP,CN,DIRECT",
  "RULE-SET,direct,DIRECT",
  "RULE-SET,proxy,🔰 选择节点",
  "MATCH,🐟 漏网之鱼",
];
const rule_providers = {
  reject: {
    type: "http",
    behavior: "domain",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/reject.txt",
    path: "./ruleset/reject.yaml",
    interval: 86400,
  },
  icloud: {
    type: "http",
    behavior: "domain",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/icloud.txt",
    path: "./ruleset/icloud.yaml",
    interval: 86400,
  },
  apple: {
    type: "http",
    behavior: "domain",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/apple.txt",
    path: "./ruleset/apple.yaml",
    interval: 86400,
  },
  google: {
    type: "http",
    behavior: "domain",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/google.txt",
    path: "./ruleset/google.yaml",
    interval: 86400,
  },
  proxy: {
    type: "http",
    behavior: "domain",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/proxy.txt",
    path: "./ruleset/proxy.yaml",
    interval: 86400,
  },
  direct: {
    type: "http",
    behavior: "domain",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/direct.txt",
    path: "./ruleset/direct.yaml",
    interval: 86400,
  },
  private: {
    type: "http",
    behavior: "domain",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/private.txt",
    path: "./ruleset/private.yaml",
    interval: 86400,
  },
  gfw: {
    type: "http",
    behavior: "domain",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/gfw.txt",
    path: "./ruleset/gfw.yaml",
    interval: 86400,
  },
  greatfire: {
    type: "http",
    behavior: "domain",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/greatfire.txt",
    path: "./ruleset/greatfire.yaml",
    interval: 86400,
  },
  "tld-not-cn": {
    type: "http",
    behavior: "domain",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/tld-not-cn.txt",
    path: "./ruleset/tld-not-cn.yaml",
    interval: 86400,
  },
  telegramcidr: {
    type: "http",
    behavior: "ipcidr",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/telegramcidr.txt",
    path: "./ruleset/telegramcidr.yaml",
    interval: 86400,
  },
  cncidr: {
    type: "http",
    behavior: "ipcidr",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/cncidr.txt",
    path: "./ruleset/cncidr.yaml",
    interval: 86400,
  },
  lancidr: {
    type: "http",
    behavior: "ipcidr",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/lancidr.txt",
    path: "./ruleset/lancidr.yaml",
    interval: 86400,
  },
  applications: {
    type: "http",
    behavior: "classical",
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/applications.txt",
    path: "./ruleset/applications.yaml",
    interval: 86400,
  },
};

module.exports.parse = (raw, { yaml }) => {
  const rawObj = yaml.parse(raw);
  delete rawObj["dns"];
  delete rawObj["fallback"];
  delete rawObj["fake-ip-filter"];
  delete rawObj["nameserver-policy"];

  const proxies = rawObj["proxies"];
  const pro = proxies.map((item) => item.name);
  const groups = [
    {
      name: "🔰 选择节点",
      type: "select",
      proxies: ["DIRECT"].concat(...pro),
    },
    {
      name: "🛑 广告拦截",
      type: "select",
      proxies: ["DIRECT", "REJECT", "🔰 选择节点"],
    },
    {
      name: "🐟 漏网之鱼",
      type: "select",
      proxies: ["DIRECT", "REJECT", "🔰 选择节点"],
    },
  ];
  return yaml.stringify({
    ...rawObj,
    dns,
    "proxy-groups": groups,
    proxies: proxies,
    rules,
    "proxy-providers": {},
    "rule-providers": rule_providers,
  });
};
