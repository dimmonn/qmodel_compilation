from sklearn.linear_model import HuberRegressor
from sklearn.metrics import r2_score
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class RobustRegressionAnalysis:
    def __init__(self):
        data_handler = DataCacheHandler(
            '../../../queries/file_change_complexity_vs_issue_pr_time.sql',
            '../../../persistence/file_change_complexity_vs_issue_pr_time.parquet'
        )

        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)

        self.original_features = ['total_additions', 'total_deletions', 'total_changes', 'files_changed']
        self.features = [f'log_{f}' for f in self.original_features]
        self.targets = ['issue_resolution_time_minutes', 'pull_request_review_time_minutes']

        # Apply log transform to handle skew and reduce outliers
        for f in self.original_features:
            self.data[f'log_{f}'] = np.log1p(self.data[f])

    def run(self):
        results = {}
        for target in self.targets:
            model = HuberRegressor()
            X = self.data[self.features]
            y = self.data[target]

            model.fit(X, y)
            y_pred = model.predict(X)

            r2 = r2_score(y, y_pred)
            results[target] = {
                'model': model,
                'r2_score': r2,
                'coefficients': model.coef_,
                'intercept': model.intercept_,
                'predictions': y_pred
            }

            print(f"\nTarget: {target}")
            print(f"R² Score: {r2:.4f}")
            print("Coefficients:")
            for feat, coef in zip(self.features, model.coef_):
                print(f"  {feat}: {coef:.4f}")

        return results

    def visualize_coefficients(self, results):
        for target, res in results.items():
            plt.figure(figsize=(8, 5))
            sns.barplot(
                x=self.features,
                y=res['coefficients'],
                palette='coolwarm'
            )
            plt.title(f'Huber Regression Coefficients for {target}')
            plt.ylabel('Coefficient')
            plt.xlabel('Feature')
            plt.xticks(rotation=45)
            plt.tight_layout()
            plt.show()

    def visualize_predictions(self, results):
        for target, res in results.items():
            plt.figure(figsize=(6, 5))
            sns.scatterplot(x=self.data[target], y=res['predictions'], alpha=0.6)
            plt.plot([self.data[target].min(), self.data[target].max()],
                     [self.data[target].min(), self.data[target].max()],
                     color='red', linestyle='--')
            plt.title(f'{target}: Actual vs. Predicted (Huber Regression)')
            plt.xlabel('Actual')
            plt.ylabel('Predicted')
            plt.tight_layout()
            plt.show()


def main():
    analysis = RobustRegressionAnalysis()
    results = analysis.run()
    analysis.visualize_coefficients(results)
    analysis.visualize_predictions(results)


if __name__ == "__main__":
    main()
