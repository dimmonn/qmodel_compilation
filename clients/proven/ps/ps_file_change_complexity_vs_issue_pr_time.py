from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class PsCodeChurnToIssuePr:
    def __init__(self):
        data_handler = DataCacheHandler('../../../queries/sql_compilation/file_change_complexity_vs_issue_pr_time.sql',
                                        '../../../persistence/file_change_complexity_vs_issue_pr_time.parquet')

        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)
        self.features = [
            'total_additions',
            'total_deletions',
            'total_changes',
            'files_changed'
        ]
        self.targets = ['issue_resolution_time_minutes', 'pull_request_review_time_minutes']

        self.strategy_name = "pearson_spearman"
        self.analysis_strategy = AnalysisFactory.get_analysis(self.strategy_name)

    def run(self):
        return self.analysis_strategy.analyze(data=self.data, features=self.features, targets=self.targets)

    def visualize(self, correlation_results):
        self.analysis_strategy.visualize_correlation(features=self.features, targets=self.targets,
                                                     results=correlation_results)

    def visualize_scatter(self):
        self.analysis_strategy._scatterplot_matrix(data=self.data,
                                                   features=self.features,
                                                   targets=self.targets)


def main():
    model = PsCodeChurnToIssuePr()
    correlation_results = model.run()
    model.visualize(correlation_results=correlation_results)
    model.visualize_scatter()


if __name__ == "__main__":
    main()
