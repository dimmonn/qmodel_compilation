from core.factories.analysis_factory import AnalysisFactory
from persistence.DataCacheHandler import DataCacheHandler


class RfCodeChurnToIssuePr:
    def __init__(self):
        data_handler = DataCacheHandler('../../../queries/file_change_complexity_vs_issue_pr_time.sql',
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

        self.strategy_name = "random_forest"
        self.analysis_strategy = AnalysisFactory.get_analysis(self.strategy_name)

    def run(self):
        return self.analysis_strategy.analyze(data=self.data, features=self.features, targets=self.targets)

    def visualize_importance(self, regression_results):
        self.analysis_strategy.visualize_importance(results=regression_results, features=self.features)

    def visualize_prediction_fit(self, regression_results):
        self.analysis_strategy.visualize_prediction_fit(results=regression_results)

    def visualize_residuals(self, regression_results):
        self.analysis_strategy.visualize_residuals(results=regression_results)


def main():
    model = RfCodeChurnToIssuePr()
    regression_results = model.run()
    model.visualize_importance(regression_results=regression_results)
    model.visualize_prediction_fit(regression_results=regression_results)
    model.visualize_residuals(regression_results=regression_results)


if __name__ == "__main__":
    main()
