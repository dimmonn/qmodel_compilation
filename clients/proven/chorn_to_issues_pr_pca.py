from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class ChornToIssuesPCA:
    def __init__(self):
        data_handler = DataCacheHandler('../../queries/sql_compilation/churn_to_issues_prs_future_avg.sql',
                                        '../../persistence/files/churn_to_quality.parquet')

        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)
        self.features = ['total_changes',
                         'total_additions',
                         'total_deletions',
                         ]
        self.targets = ['avg_issue_resolution_time_days', 'avg_pr_review_time_days',
                        'num_of_prs_opened_after_commit_date',
                        'num_of_issues_opened_after_commit_date']
        strategy_name = "pca"
        self.analysis_strategy = AnalysisFactory.get_analysis(strategy_name)

    def run(self):
        return self.analysis_strategy.analyze(data=self.data, features=self.features, targets=self.targets)

    def visualize(self, correlation_results):
        self.analysis_strategy.visualize_pca(features=self.features, results=correlation_results)


def main():
    model = ChornToIssuesPCA()
    correlation_results = model.run()
    model.visualize(correlation_results=correlation_results)


if __name__ == "__main__":
    main()
