@modules_autoload_list = [
    'base.rb',
    'gpu_miners/gpu_miner_base.rb',
    'cpu_miners/cpu_miner_base.rb',
    'miner_pools/miner_pool_base.rb',
    'other/portfolio_base.rb',
]

@modules_registered = [
# WTH System modules
    ['WthLink','','wth','wth_link'],
# GPU Miners
    ['Excavator','gpu_miners','excavator','nice_hash_qm','nice_hash'],
    ['Phoenix','gpu_miners','phoenix'],
    ['TRexMiner','gpu_miners','t_rex','trex'],
    ['GMiner','gpu_miners','gminer','g_miner'],
    ['LolMiner','gpu_miners','lol_miner','lolminer'],
    ['NanoMiner','gpu_miners','nano_miner','nanominer'],
    ['TeamRedClaymore','gpu_miners','teamred','teamredminer','teamred_claymore'],
    ['NBMiner','gpu_miners','nb_miner','nbminer'],
# CPU Miners
    ['Xmrig','cpu_miners','xmrig'],
    ['Cpuminer','cpu_miners','raptoreum','cpuminer'],
# Miner Pools
    ['Unmineable','miner_pools','unmineable'],
    ['FlockPool','miner_pools','flock_pool','flockpool'],
    ['NanoPool','miner_pools','nano_pool','nanopool'],
    ['TwoMinersPool','miner_pools','2miners_pool','2miner_pool','2minerspool','2minerpool'],
# Portfolio
    ['CoinGeckoTracker','other','coin_gecko','portfolio'],
# PoC+/PoC/PoCC miners
    ['SignumPoolMiner','other','signum_pool_miner'],
    ['SignumPoolView','other','signum_pool_view'],
    ['SignumAssetView','other','signum_asset_view'],
# Hardware
    ['OhmGpuWin32','hardware','ohm_gpu_w32','lhm_gpu_win32'],
    ['SmiRest','hardware','smirest','smi_rest'],
# DeFi
    ['ZapperFi','defi','zapper_fi'],
# Blockchain
#    ['Ethplorer','blockchain','ethplorer'],
# Formating
    ['Banner','other','banner'],
]
