# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# https://signawallet.notallmine.net/burst?requestType=getAccount&account=S-39C7-CS43-QPMM-FXMJ3
# https://signawallet.notallmine.net/burst?requestType=getAsset&asset=12402415494995249540
#
class Modules::SignumAssetView < Modules::Base
  using IndifferentHash  

  SIGNUM_API_LIST = [
    		"https://europe2.signum.network",
    		"https://europe.signum.network",
    		"https://europe1.signum.network",
    		"https://europe3.signum.network",
    		"https://brazil.signum.network",
    		"https://uk.signum.network",
#    		BT.NODE_BURSTCOIN_RO,
    		"https://canada.signum.network",
    		"https://australia.signum.network",
  ]
  SIGNUM_API_NODE = "https://signawallet.notallmine.net" #"https://canada.signum.network"

  def initialize(p={})
    super
    @signum_api_node = @config["api_node"] || SIGNUM_API_NODE
    @title = @config["title"] || 'Signum Asset View'
    @coin = "signa"
    @frequency  = @config["every"] || @config["default_frequency"] || 180
    @frequency  = 60 if @frequency < 60
    @desc_len = @config["description_length"] || 50
    @lifespan = @config["lifespan"] || 120
    @lifespan = 60 if @lifespan < 60
    @cache = Lightly.new dir: 'tmp/signum_cache', life: @lifespan, hash: false
    @headers = [
      "Account","Token","Balance",#"Confirmed",
      "AssetID","Address","Token Desc"
    ]
  end

  def get_asset(url,asset)
    @cache.get("asset_#{asset}"){
      simple_rest("#{url}/burst?requestType=getAsset&asset=#{asset}")
    }
  end

  def check(url,addr)
    res = node_structure
    url = url && !url.empty? ? url : @signum_api_node
    res1 = simple_rest("#{url}/burst?requestType=getAccount&account=#{addr}")
    res.name = res1["name"]
    res.balance = res1["balanceNQT"].to_f / 100000000.0
    res.account = res1["account"]
    res.address = res1["accountRS"]

    res1["assetBalances"] ||= []
    res1["assetBalances"].each {|ab|
      ab_res = get_asset(url,ab["asset"])
      as = asset_structure
      as.asset = ab["asset"]
      as.name = ab_res["name"]
      as.address = ab_res["accountRS"]
      as.account = ab_res["account"]
      as.description = ab_res["description"].gsub(/[\r|\n]/,' ')
      as.decimals = ab_res["decimals"].to_i
      as.balance = ab["balanceQNT"].to_f * ( 1.0/10.pow(as.decimals) )
      res.assets[as.asset] = as
    }
    res
  end

  def node_structure
    OpenStruct.new({
      address: "",
      name: "",
      account: "",
      balance: 0.0,
      assets: {}
    })
  end

  def asset_structure
    OpenStruct.new({
      asset: "",
      name: "",
      description: "",
      address: "",
      account: "",
      balance: 0.0,
      confirmed: false,
      decimals: 0
    })
  end

  def tableize(data)
    tables = []
    tables << super(data) do |item,rows,formats|
      item["assets"].keys.sort.each_with_index{|k,ai|
        v = item["assets"][k]
        rows << [
          item.name, v.name, v.balance,
          v.asset, v.address, "#{v.description[0..@desc_len]} ..."
        ]
      }
    end
    tables
  end

end