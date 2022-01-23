# Author: BeRogue01
# License: See LICENSE file
# Date: 2022/01
#
# https://api.zapper.fi/v1/balances?addresses[]=0x2e3b3dfe5812e2b283abfd9d7fd91257e3b04e20&nonNilOnly=true&networks[]=ethereum&networks[]=avalanche&api_key=5d1237c2-3840-4733-8e92-c5a58fe81b88
#
class Modules::ZapperFi < Modules::Base
  using IndifferentHash  

  API_HOST = "https://api.zapper.fi"

  NETWORKS = [
    'ethereum',
    'polygon',
    'optimism',
    'xdai',
    'binance-smart-chain',
    'fantom',
    'avalanche',
    'arbitrum',
    'celo',
    'harmony',
    'moonriver',
  ]

  def initialize(p={})
    super
    @title = p[:title] || 'Zapper.Fi (https://zapper.fi)'
    @api_key = @config['api_key'] || "5d1237c2-3840-4733-8e92-c5a58fe81b88"
    @lifespan = @config["lifespan"] || 300
    @lifespan = 60 if @lifespan < 60
    @frequency = 60 if @frequency < 60
    @cache = Lightly.new dir: 'tmp/zapper_fi_cache', life:300, hash: false
    @threads = {}
    @headers = ['Name','Addr','Network','App','Label','Asset Type','Token Type','Category','Symbol','Linked','Value$','Balance','Price','Tkn Addr']
  end

  def check(dat,name)
    network,addr = dat.split(':')
    addr = addr.downcase
    if !NETWORKS.include?(network)
      fail("#{self.class.name} :: #{name} :: Network not defined #{network}")
    end

    ckey = name
    ret = if @threads[ckey]
      val = @threads[ckey].value!(0.25)
      if val
        @threads.delete(ckey)
        val
      else
        warn_structure(name,dat)
      end
    else
      @threads[ckey] = Concurrent::Promises.future(ckey) do |ckey|
        resp = simple_http_request("#{API_HOST}/v1/balances?addresses[]=#{addr}&networks[]=#{network}&nonNilOnly=true&api_key=#{@api_key}",180)
        lines = resp.split("\n")
        resdata = []
        lines.each{|l|
          next if l !~ /data\:\s\{/
          resdata << JSON.parse(l.split('data: ')[1])
        }
        format(dat,name,resdata)
      end
      warn_structure(name,dat)
    end
    return ret
  rescue => e
    @threads.delete(ckey)
    raise e
  end

  def format(dat,name,resdata)
    network,addr = dat.split(':')
    addr = addr.downcase

    out = node_structure
    out.name = name
    out.address = addr
    out.private_address = private_address(addr)

    resdata.each{|d|
      o = OpenStruct.new()
      o.network = d["network"]
      o.app = d["appId"]
      o.products = []
      d["balances"][addr]["products"].each{|p|
        product = OpenStruct.new()
        product.type = p["label"]
        product.assets = []
        p["assets"].each{|as|
          asset = OpenStruct.new()
          asset.type = as["type"]
          asset.balance = as["balanceUSD"].to_f
          asset.tokens = []
          token_dive(as["tokens"],asset.tokens)
          product.assets << asset
        }
        o.products << product
      }
      out.entries << o
    }
    out
  end

  def node_structure
    OpenStruct.new({
      entries: [],
      name: "",
      address: "",
      private_address: "",
      state: '',
      status: '',
      target: ''
    })
  end

  def warn_structure(name,dat)
    h = node_structure
    h.name = name
    h.state = 'pending_update'
    h
  end

  def token_dive(dat,tokens,parent="")
    dat.each{|tdat|
      t = OpenStruct.new()
      t.type= tdat["type"]
      t.parent = parent
      t.category= tdat["category"]
      t.symbol= tdat["symbol"]
      t.balance= tdat["balance"].to_f
      t.value_usd= tdat["balanceUSD"].to_f
      t.price_usd= tdat["price"].to_f
      t.address = tdat["address"]
      t.private_address = private_address(t.address)
      tokens << t
      token_dive(tdat["tokens"],tokens,t.symbol) if tdat["tokens"]
    }
    tokens
  end

  def tableize(data)
    tables = []
    tables << super(data) do |item,rows,formats|
      item.entries.each{|it|
      it.products.each{|p|
        p.assets.each{|a|
          a.tokens.each{|t|
            rows << [
              item.name,
              item.private_address,
              it.network,
              it.app,
              p.type,
              a.type,
              t.type,
              t.category,
              t.symbol,
              t.parent,
              sprintf("$%0.2f",t.value_usd),
              t.balance,
              sprintf("$%0.2f",t.price_usd),
              t.private_address
            ]
          }
        }
      }}
    end
    tables
  end

end