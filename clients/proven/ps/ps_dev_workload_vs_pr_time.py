from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class PsInactivityToIssuesPr:
    def __init__(self):
        data_handler = DataCacheHandler('../../../queries/sql_compilation/dev_workload_vs_pr_time.sql',
                                        '../../../persistence/files/sp/dev_workload_vs_pr_time.parquet')

        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)
        self.features = [
            'open_issues_at_time',
            'open_prs_at_time'
        ]
        self.targets = ['pr_review_time']

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
    model = PsInactivityToIssuesPr()
    correlation_results = model.run()
    model.visualize(correlation_results=correlation_results)
    model.visualize_scatter()


if __name__ == "__main__":
    main()
