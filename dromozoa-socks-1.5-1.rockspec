package = "dromozoa-socks"
version = "1.5-1"
source = {
  url = "https://github.com/dromozoa/dromozoa-socks/archive/v1.5.tar.gz";
  file = "dromozoa-socks-1.5.tar.gz";
}
description = {
  summary = "Toolkit for network and I/O programming";
  license = "GPL-3";
  homepage = "https://github.com/dromozoa/dromozoa-socks/";
  maintainer = "Tomoyuki Fujimori <moyu@dromozoa.com>";
}
dependencies = {
  "dromozoa-future";
}
build = {
  type = "builtin";
  modules = {};
  install = {
    bin = {
      ["dromozoa-socks"] = "dromozoa-socks";
    };
  };
}
