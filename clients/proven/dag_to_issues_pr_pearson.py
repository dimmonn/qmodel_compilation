from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class DagToIssuesPrPearson:
    def __init__(self):
        data_handler = DataCacheHandler('../../queries/dag_to_issues_prs_future_avg.sql',
                                        '../../persistence/dag_to_issues.parquet')

        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)
        self.features = [
            'commitCount',
            'max_commit_depth',
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
        self.analysis_strategy = AnalysisFactory.get_analysis(self.strategy_name)

    def run(self):
        return self.analysis_strategy.analyze(data=self.data, features=self.features, targets=self.targets)

    def visualize(self, correlation_results):
        self.analysis_strategy.visualize_correlation(features=features, results=correlation_results)


def main():
    model = DagToIssuesPrPearson()
    correlation_results = model.run()
    model.visualize(correlation_results=correlation_results)


if __name__ == "__main__":
    main()
