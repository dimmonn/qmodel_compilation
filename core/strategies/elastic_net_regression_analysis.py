from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import ElasticNetCV
from core.correlation_analysis_factory import AnalysisStrategy
import numpy as np


class ElasticNetRegressionAnalysis(AnalysisStrategy):
    def __init__(self, random_state=42):
        self.random_state = random_state

    def analyze(self, data, features, targets):
        results = {}
        X = data[features].values

        for target in targets:
            y = np.log1p(data[target].values)

            pipe = Pipeline([
                ("scaler", StandardScaler()),
                ("enet", ElasticNetCV(
                    l1_ratio=[0.1, 0.5, 0.9],
                    cv=5,
                    random_state=self.random_state
                ))
            ])
            pipe.fit(X, y)

            enet = pipe.named_steps["enet"]
            coef = enet.coef_

            results[target] = pd.DataFrame({
                "feature": features,
                "coefficient": coef
            }).sort_values("coefficient", ascending=False)

        return results
