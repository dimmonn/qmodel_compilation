from persistence.DataCacheHandler import DataCacheHandler
from context.rf_context import RfContext
from core.strategies.random_forest import RandomForestAnalysis
from core.factories.analysis_factory import AnalysisFactory


class PsInactivityToIssuesPr:
    def __init__(self):
        data_handler = DataCacheHandler('../../../queries/dag_to_issues.sql',
                                        '../../../persistence/rf_dag_to_issues.parquet')

        self.data = data_handler.load_from_parquet()
        self.data.fillna(0, inplace=True)
        self.features = [
            'in_degree',
            'out_degree',
            'average_degree',
            'merge_count'
        ]
        self.targets = ['issue_resolution_time']

        self.strategy_name = "random_forest"
        self.analysis_strategy: RandomForestAnalysis = AnalysisFactory.get_analysis(self.strategy_name)
        self.context = RfContext(self.analysis_strategy, self.data)

    def run(self):
        return self.analysis_strategy.analyze(data=self.data, features=self.features, targets=self.targets)

    def visualize_importance(self, regression_results):
        self.analysis_strategy.visualize_importance(results=regression_results, features=self.features)

    def visualize_prediction_fit(self, regression_results):
        self.analysis_strategy.visualize_prediction_fit(results=regression_results)

    def visualize_residuals(self, regression_results):
        self.analysis_strategy.visualize_residuals(results=regression_results)


def main():
    model = PsInactivityToIssuesPr()
    regression_results = model.run()
    model.visualize_importance(regression_results=regression_results)
    model.visualize_prediction_fit(regression_results=regression_results)
    model.visualize_residuals(regression_results=regression_results)


if __name__ == "__main__":
    main()
