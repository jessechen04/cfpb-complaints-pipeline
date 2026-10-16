# import pandas as pd
# from sklearn.preprocessing import StandardScaler
# from sklearn.cluster import KMeans

# df = pd.DataFrame({
#     "state": ["GA", "VT", "FL", "ME"],
#     "complaints_per_100k": [900, 200, 950, 220],
#     "pct_untimely": [4, 2, 5, 1],
# })

# X = StandardScaler().fit_transform(df[["complaints_per_100k", "pct_untimely"]])
# df["cluster"] = KMeans(n_clusters=2, n_init=10, random_state=0).fit_predict(X)
# print(df)


from google.cloud import bigquery
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

df = bigquery.Client().query("SELECT * FROM `cfpb-complaints-pipeline.cfpb.state_features`").to_dataframe()

X = StandardScaler().fit_transform(df.drop(columns=["state"]))

for k in range(2, 8):
    labels = KMeans(n_clusters=k, n_init=10, random_state=0).fit_predict(X)
    print(k, silhouette_score(X, labels))