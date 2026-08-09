// Clash Verge Rev: 全局扩展脚本（桌面端 / Mihomo）
// 按需修改 CUSTOM_RULES、校园网 SOCKS 端口和策略组名称。
function main(content, profileName) {
  const SELECT = "🔰 选择节点";
  const CAMPUS = "校园网";
  const REJECT = "🛑 广告拦截";
  const FINAL = "🐟 漏网之鱼";
  const CAMPUS_PROXY = "HITSZ Connect Verge";
  // 内置 DIRECT 不会在 Verge 中保留延迟记录；此可配置直连出站用于测速。
  const DIRECT_TEST = "DIRECT 测速";

  const isPlainObject = (value) => value !== null && typeof value === "object" && !Array.isArray(value);
  // 只保留确有兼容性需求的条目；不要把整个 QQ / 腾讯 / Apple / Google 域名加入此处，
  // 否则会绕开 fake-ip，降低规则匹配与嗅探的一致性。
  const fakeIpFilter = [
    "+.lan", "+.local", "*.localdomain", "*.example", "*.invalid", "*.localhost", "*.test", "*.home.arpa",
    "+.msftconnecttest.com", "+.msftncsi.com",
    "localhost.ptlogin2.qq.com", "localhost.sec.qq.com", "localhost.work.weixin.qq.com",
    "+.srv.nintendo.net", "+.stun.playstation.net", "+.xboxlive.com",
    "stun.*.*", "stun.*.*.*", "+.stun.*.*", "+.stun.*.*.*",
    "+.pool.ntp.org", "time.apple.com", "time-ios.apple.com", "time1.cloud.tencent.com",
    "+.linksys.com", "+.linksyssmartwifi.com", "+.router.asus.com",
    // 音乐 App / 游戏如遇登录、播放或联机异常，再有针对性地添加域名即可。
  ];

  const domesticNameservers = [
    "https://dns.alidns.com/dns-query",
    "https://doh.pub/dns-query",
  ];
  // #策略组 让境外 DoH 请求随所选节点发出，避免直连被污染或阻断。
  const foreignNameservers = [
    `https://cloudflare-dns.com/dns-query#${SELECT}`,
    `https://dns.google/dns-query#${SELECT}`,
    `https://dns.quad9.net/dns-query#${SELECT}`,
  ];

  const dnsConfig = {
    enable: true,
    // Verge 是桌面客户端，避免占用 53 端口或向局域网暴露 DNS 服务。
    listen: "127.0.0.1:1053",
    ipv6: true,
    "use-system-hosts": true,
    "cache-algorithm": "arc",
    "prefer-h3": false,
    "respect-rules": true,
    "enhanced-mode": "fake-ip",
    "fake-ip-range": "198.18.0.1/16",
    "fake-ip-filter": fakeIpFilter,
    // 仅用于解析 DoH 主机名：必须能在无代理时使用。
    "default-nameserver": ["223.5.5.5", "119.29.29.29"],
    nameserver: [...domesticNameservers, ...foreignNameservers],
    // 节点服务器域名必须在代理建立前解析，故只放可直连的国内 DNS。
    "proxy-server-nameserver": domesticNameservers,
    "nameserver-policy": {
      "geosite:private,cn,geolocation-cn": domesticNameservers,
      "geosite:google,youtube,telegram,gfw,geolocation-!cn": foreignNameservers,
    },
  };

  const ruleProviderBase = {
    type: "http",
    behavior: "domain",
    format: "yaml",
    interval: 86400,
    // 更新规则集也使用所选代理；首次无可用节点时可暂时删除这一行排障。
    proxy: SELECT,
  };
  const ruleUrl = (name) => `https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/${name}.txt`;
  const domainRule = (name) => ({ ...ruleProviderBase, url: ruleUrl(name), path: `./ruleset/loyalsoldier/${name}.yaml` });
  const ipRule = (name) => ({ ...ruleProviderBase, behavior: "ipcidr", url: ruleUrl(name), path: `./ruleset/loyalsoldier/${name}.yaml` });

  const ruleProviders = {
    reject: domainRule("reject"),
    icloud: domainRule("icloud"),
    apple: domainRule("apple"),
    google: domainRule("google"),
    private: domainRule("private"),
    direct: domainRule("direct"),
    proxy: domainRule("proxy"),
    gfw: domainRule("gfw"),
    greatfire: domainRule("greatfire"),
    "tld-not-cn": domainRule("tld-not-cn"),
    applications: { ...domainRule("applications"), behavior: "classical" },
    telegramcidr: ipRule("telegramcidr"),
    lancidr: ipRule("lancidr"),
    cncidr: ipRule("cncidr"),
  };

  // 所有自定义规则必须放在通用规则集之前。规则字段中不要在逗号后留空格。
  const CUSTOM_RULES = [
    "DOMAIN,vpn.hust.edu.cn,DIRECT",
    `DOMAIN-SUFFIX,hust.edu.cn,${CAMPUS}`,
    `IP-CIDR,202.114.0.0/16,${CAMPUS},no-resolve`,
    `IP-CIDR,211.68.0.0/16,${CAMPUS},no-resolve`,
    `DOMAIN-SUFFIX,github.com,${SELECT}`,
    `DOMAIN-SUFFIX,ipv6boy.xyz,${SELECT}`,
    `DOMAIN-SUFFIX,edaplayground.com,${SELECT}`,
    `DOMAIN-SUFFIX,docker.io,${SELECT}`,
    "DOMAIN-SUFFIX,byr.pt,DIRECT",
    "DOMAIN-SUFFIX,pandapt.net,DIRECT",
    "DOMAIN-SUFFIX,gstatic.com,DIRECT",
    "DOMAIN-SUFFIX,acm.org,DIRECT",
    "DOMAIN-SUFFIX,ieee.org,DIRECT",
    `DOMAIN,hdlbits.01xz.net,${SELECT}`,
    `DOMAIN,sub.198477.xyz,${SELECT}`,
    "DOMAIN-SUFFIX,steamcontent.com,DIRECT",
    "DOMAIN-SUFFIX,steamstatic.com,DIRECT",
    "DOMAIN-SUFFIX,steamserver.net,DIRECT",
    "DOMAIN-SUFFIX,test.steampowered.com,DIRECT",
    "DOMAIN-SUFFIX,rmbgame.net,DIRECT",
    "DOMAIN,clash.razord.top,DIRECT",
    "DOMAIN,local.adguard.org,DIRECT",
    "DOMAIN,yacd.haishan.me,DIRECT",
    `DOMAIN,injections.adguard.org,${SELECT}`,
    `DOMAIN,垃圾场珀.com,${SELECT}`,
    `DOMAIN,垃圾场六.com,${SELECT}`,
    `DOMAIN-SUFFIX,akamaized.net,${SELECT}`,
  ];

  const rules = [
    ...CUSTOM_RULES,
    "RULE-SET,applications,DIRECT",
    "RULE-SET,private,DIRECT",
    `RULE-SET,reject,${REJECT}`,
    "RULE-SET,icloud,DIRECT",
    "RULE-SET,apple,DIRECT",
    `RULE-SET,google,${SELECT}`,
    `RULE-SET,tld-not-cn,${SELECT}`,
    `RULE-SET,gfw,${SELECT}`,
    `RULE-SET,greatfire,${SELECT}`,
    `RULE-SET,telegramcidr,${SELECT}`,
    "RULE-SET,lancidr,DIRECT,no-resolve",
    "RULE-SET,cncidr,DIRECT,no-resolve",
    "RULE-SET,direct,DIRECT",
    `RULE-SET,proxy,${SELECT}`,
    "GEOIP,LAN,DIRECT,no-resolve",
    "GEOIP,CN,DIRECT,no-resolve",
    `MATCH,${FINAL}`,
  ];

  const existingProxies = Array.isArray(content.proxies) ? content.proxies.filter(isPlainObject) : [];
  // 在加入本地出站前记录订阅节点，主选择组只显示这些节点和可测速直连。
  const subscriptionProxyNames = [...new Set(
    existingProxies.map((proxy) => proxy.name).filter((name) =>
      typeof name === "string" && name && name !== CAMPUS_PROXY && name !== DIRECT_TEST
    )
  )];
  if (!existingProxies.some((proxy) => proxy.name === DIRECT_TEST)) {
    existingProxies.push({ name: DIRECT_TEST, type: "direct", udp: true });
  }
  if (!existingProxies.some((proxy) => proxy.name === CAMPUS_PROXY)) {
    existingProxies.push({ name: CAMPUS_PROXY, type: "socks5", server: "127.0.0.1", port: 11080, udp: true });
  }
  // select 组同样支持健康检查；DIRECT 在该组中，所以会一并得到延迟数据。
  // 这只负责测速，不会自动切换你手动选定的节点。
  const selectionHealthCheck = {
    url: "https://www.gstatic.com/generate_204",
    interval: 300,
    timeout: 5000,
    lazy: true,
    "max-failed-times": 3,
  };
  const groups = [
    { ...selectionHealthCheck, name: SELECT, type: "select", proxies: [DIRECT_TEST, ...subscriptionProxyNames] },
    { name: REJECT, type: "select", proxies: ["REJECT", "DIRECT", SELECT] },
    { name: FINAL, type: "select", proxies: [SELECT, "DIRECT", "REJECT"] },
    { name: CAMPUS, type: "select", proxies: ["DIRECT", CAMPUS_PROXY] },
  ];

  content.proxies = existingProxies;
  content.dns = dnsConfig;
  content["proxy-groups"] = groups;
  content["rule-providers"] = ruleProviders;
  content.rules = rules;
  content["unified-delay"] = true;
  content["tcp-concurrent"] = true;
  content.profile = { ...(isPlainObject(content.profile) ? content.profile : {}), "store-selected": true, "store-fake-ip": true };
  content.sniffer = {
    enable: true,
    sniff: {
      TLS: { ports: [443, 8443] },
      HTTP: { ports: [80, "8080-8880"], "override-destination": true },
    },
  };
  content["geodata-mode"] = true;
  content["geo-auto-update"] = true;
  content["geo-update-interval"] = 24;
  content["geox-url"] = {
    geoip: "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat",
    geosite: "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat",
    mmdb: "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country-lite.mmdb",
  };

  return content;
}
