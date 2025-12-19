from core.correlation_analysis_factory import AnalysisStrategy
import statsmodels.api as sm
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
class LinearRegressionAnalysis(AnalysisStrategy):

    def analyze(self, data, features, targets):
        results = {}

        for target in targets:

            X = data[features].copy()

            # ---- Clean and validate ----
            X = X.apply(pd.to_numeric, errors="coerce")     # convert invalid to NaN
            X = X.dropna(axis=1, how='all')                 # remove all-NaN columns
            X = X.loc[:, X.std(ddof=0) > 0]                 # remove constant columns

            # Normalization (safe)
            X = (X - X.mean()) / (X.std(ddof=0).replace(0, 1))

            # Add intercept
            X = sm.add_constant(X)

            y = pd.to_numeric(data[target], errors="coerce")

            # Fit
            model = sm.OLS(y, X, missing='drop').fit()

            results[target] = pd.DataFrame({
                "feature": model.params.index,
                "coefficient": model.params.values,
                "p_value": model.pvalues.values
            })

        return results

    def visualize_regression(self, results, features, targets, owner):
        for target in targets:
            df = results[target]
            df = df[df['feature'] != 'const'].reset_index(drop=True)  # << reset index

            plt.figure(figsize=(12, 5))
            ax = sns.barplot(x='feature', y='coefficient', data=df, palette='coolwarm')

            for j, row in df.iterrows():  # j is now 0..n-1
                significance = ''
                if row['p_value'] < 0.001:
                    significance = '***'
                elif row['p_value'] < 0.01:
                    significance = '**'
                elif row['p_value'] < 0.05:
                    significance = '*'

                ax.text(j, row['coefficient'], significance,
                        ha='center', va='bottom')

            plt.title(f'Linear Regression Coefficients for {target} for {owner}')
            plt.xticks(rotation=45, ha='right')
            plt.axhline(0, color='gray', linestyle='--')
            plt.tight_layout()
            plt.show()


    def visualize_scatter(self, data, features, targets):
        import seaborn as sns
        import matplotlib.pyplot as plt

        for target in targets:
            for feature in features:
                plt.figure(figsize=(8, 5))
                sns.scatterplot(x=data[feature], y=data[target], alpha=0.5)
                sns.regplot(x=data[feature], y=data[target], scatter=False, color='red', ci=None)
                plt.xlabel(feature)
                plt.ylabel(target)
                plt.title(f'{feature} vs {target} (Linear Fit)')
                plt.tight_layout()
                plt.show()