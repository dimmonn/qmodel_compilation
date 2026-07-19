from statsmodels.stats.outliers_influence import variance_inflation_factor
import pandas as pd
from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler

class BidToIssuesPearsonCorrelation:
    def __init__(self):
        data_handler = DataCacheHandler('../../queries/sql_compilation/bug_introduced_defects_to_issues.sql',
                                        '../../persistence/files/bug_introduced_defects_to_issues.parquet')



        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)
        self.features = ['average_degree',
                         'comment_count',
                         'in_degree',
                         'max_depth_of_commit_history',
                         'merge_count',
                         'min_depth_of_commit_history',
                         'num_of_files_changed',
                         'number_of_branches',
                         'number_of_edges',
                         'number_of_vertices',
                         'out_degree'
                         ]
        self.targets = ['fix_time_minutes']

        self.strategy_name = "pearson_spearman"
        self.analysis_strategy = AnalysisFactory.get_analysis(self.strategy_name)


    def run(self):
        return self.analysis_strategy.analyze(data=self.data, features=self.features, targets=self.targets)

    def visualize(self, correlation_results):
        self.analysis_strategy.visualize_correlation(features=self.features, targets=self.targets, results=correlation_results)


def main():
    model = BidToIssuesPearsonCorrelation()
    correlation_results = model.run()
    model.visualize(correlation_results=correlation_results)


if __name__ == "__main__":
    main()
