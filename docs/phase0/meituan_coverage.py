import sys
import pandas as pd
df = pd.read_csv(sys.argv[1], usecols=["dt","poi_id","is_prebook","fetch_time","platform_order_time","sender_lng","sender_lat","da_id"])
print("orders per dt:", dict(df.dt.value_counts().sort_index()))
done = df[df.fetch_time > 0]
print("delivered (fetch>0):", len(done), "of", len(df), "| prebook share:", round(df.is_prebook.mean(), 4))
c = done.groupby("poi_id").size()
for k in [1, 10, 30, 100, 500]:
    print(f"POIs with >= {k} picked-up orders: {(c >= k).sum()}  (cover {round(c[c >= k].sum() / c.sum() * 100, 1)}% of orders)")
print("sender_lng range /1e6:", df.sender_lng.min() / 1e6, df.sender_lng.max() / 1e6, "| sender_lat /1e6:", df.sender_lat.min() / 1e6, df.sender_lat.max() / 1e6)
o2p = (done.fetch_time - done.platform_order_time) / 60
np_ = done[done.is_prebook == 0]
o2p_np = (np_.fetch_time - np_.platform_order_time) / 60
print("order->pickup (non-prebook) min:", o2p_np.describe(percentiles=[.01, .5, .99]).round(2).to_dict())
print("share > 120 min (non-prebook):", round((o2p_np > 120).mean() * 100, 3), "%")
