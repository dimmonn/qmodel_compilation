from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class PsInactivityToIssuesPr:
    def __init__(self):
        data_handler = DataCacheHandler('../../../queries/fp_dag_to_quality.sql',
                                        '../../../persistence/fp_dag_to_quality.parquet')

        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)
        self.features = [
            'num_of_files_changed',
            'average_degree',
            'in_degree',
            'out_degree',
            'number_of_edges',
            'max_depth_of_commit_history',
            'max_depth_of_commit_history',
            'distance_to_branch_start',
            'upstream_heads_unique_on_segment'

        ]
        self.targets = ['avg_issue_resolution_hours', 'avg_pr_review_hours']

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
