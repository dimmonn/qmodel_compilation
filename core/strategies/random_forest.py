from core.correlation_analysis_factory import AnalysisStrategy
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import r2_score, mean_squared_error
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd

class RandomForestAnalysis(AnalysisStrategy):
    def __init__(self, n_estimators=200, random_state=42, max_depth=None):
        self.n_estimators = n_estimators
        self.random_state = random_state
        self.max_depth = max_depth

    def analyze(self, data, features, targets):
        results = {}

        for target in targets:
            train_data = data[data['dataset_split'] == 'train']
            valid_data = data[data['dataset_split'] == 'validation']

            X_train = train_data[features]
            y_train = train_data[target]

            X_valid = valid_data[features]
            y_valid = valid_data[target]
            model = RandomForestRegressor(
                n_estimators=self.n_estimators,
                random_state=self.random_state,
                max_depth=self.max_depth,
                n_jobs=-1
            )
            model.fit(X_train, y_train)

            y_pred = model.predict(X_valid)

            mse = mean_squared_error(y_valid, y_pred)
            r2 = r2_score(y_valid, y_pred)

            results[target] = {
                "model": model,
                "r2_score": r2,
                "mse": mse,
                "y_true": y_valid,
                "y_pred": y_pred,
                "feature_importances": model.feature_importances_,
            }
        return results


    def visualize_importance(self, results, features, owner):
        for target, res in results.items():
            importances = res["feature_importances"]
            sorted_idx = np.argsort(importances)[::-1]
            sorted_features = np.array(features)[sorted_idx]
            sorted_importances = importances[sorted_idx]
            plt.figure(figsize=(10, 6))
            sns.barplot(x=sorted_importances, y=sorted_features, palette="viridis")
            plt.title(f"Feature Importances for predicting {target} for {owner}")
            plt.xlabel("Importance")
            plt.ylabel("Feature")
            plt.tight_layout()
            plt.show()

    def visualize_prediction_fit(self, results, owner):
        for target, res in results.items():
            plt.figure(figsize=(6, 5))
            sns.scatterplot(x=res["y_true"], y=res["y_pred"], alpha=0.6)
            plt.plot([res["y_true"].min(), res["y_true"].max()],
                     [res["y_true"].min(), res["y_true"].max()], 'r--')
            plt.xlabel("Actual")
            plt.ylabel("Predicted")
            plt.title(f"Actual vs Predicted: {target} for {owner}")
            plt.tight_layout()
            plt.show()

    def visualize_residuals(self, results, owner):
        for target, res in results.items():
            residuals = res["y_true"] - res["y_pred"]
            plt.figure(figsize=(6, 4))
            sns.histplot(residuals, bins=50, kde=True)
            plt.title(f"Residuals for {target} for {owner}")
            plt.xlabel("Residual")
            plt.tight_layout()
            plt.show()

    def visualize_metrics(self, results, owner):
        for target, res in results.items():
            metric_names = ["R2 score", "MSE"]
            metric_values = [
                res["r2_score"],
                res["mse"],
            ]

            plt.figure(figsize=(6, 4))
            sns.barplot(x=metric_names, y=metric_values)

            plt.title(f"Model metrics for {target} for {owner}")
            plt.ylabel("Value")
            plt.xlabel("Metric")

            for i, value in enumerate(metric_values):
                plt.text(
                    i,
                    value,
                    f"{value:.4f}",
                    ha="center",
                    va="bottom",
                )

            plt.tight_layout()
            plt.show()