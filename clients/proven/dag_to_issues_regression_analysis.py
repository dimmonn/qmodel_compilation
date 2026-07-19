import statsmodels.api as sm
from statsmodels.stats.outliers_influence import variance_inflation_factor
import pandas as pd

from scipy.stats import pearsonr, spearmanr
import seaborn as sns
import matplotlib.pyplot as plt

from persistence.DataCacheHandler import DataCacheHandler

from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler

from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler

from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class DagRegressionAnalisys:
    def __init__(self):
        data_handler = DataCacheHandler('../../queries/sql_compilation/dag_to_issues_prs_future_avg.sql',
                                        '../persistence/files/dag_to_quality.parquet')

        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)
        self.features = ['max_commit_depth',
                         'min_commit_depth',
                         'avg_degree',
                         'max_degree',
                         'max_branches',
                         'max_edges',
                         'max_vertices',
                         'max_files_changed'
                         ]
        self.targets = ['avg_issue_resolution_time_days', 'avg_pr_review_time_days',
                        'num_of_prs_opened_after_commit_date',
                        'num_of_issues_opened_after_commit_date']

        self.strategy_name = "pearson_spearman"
        self.analysis_strategy = AnalysisFactory.get_analysis(strategy_name)

    def run(self):
        return self.analysis_strategy.analyze(data=self.data, features=self.features, targets=self.targets)

    def visualize(self, correlation_results):
        self.analysis_strategy.visualize_correlation(features=features, results=correlation_results)


def main():
    model = DagRegressionAnalisys()

    X = model.data[model.features]
    y = model.data[model.targets]
    # for target in targets:
    #     y = data[target]  # Select one target at a time
    #     model = sm.OLS(y, X).fit()
    #     print(f"\nRegression results for: {target}")
    #     print(model.summary())

    vif_data = pd.DataFrame()
    vif_data["feature"] = X.columns
    vif_data["VIF"] = [variance_inflation_factor(X.values, i) for i in range(X.shape[1])]
    print(vif_data)


if __name__ == "__main__":
    main()
