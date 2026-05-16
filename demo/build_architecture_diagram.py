from __future__ import annotations

from pathlib import Path
import textwrap

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_PATH = PROJECT_ROOT / "img_architecture.png"


def _add_box(ax, xy, width, height, title, body, facecolor, edgecolor="#243447", text_color="#102030"):
    box = FancyBboxPatch(
        xy,
        width,
        height,
        boxstyle="round,pad=0.02,rounding_size=0.03",
        linewidth=1.8,
        facecolor=facecolor,
        edgecolor=edgecolor,
        mutation_aspect=1,
    )
    ax.add_patch(box)

    x, y = xy
    ax.text(
        x + width / 2,
        y + height * 0.68,
        title,
        ha="center",
        va="center",
        fontsize=13,
        fontweight="bold",
        color=text_color,
    )
    ax.text(
        x + width / 2,
        y + height * 0.32,
        "\n".join(textwrap.wrap(body, width=24)),
        ha="center",
        va="center",
        fontsize=9.5,
        color=text_color,
        linespacing=1.3,
    )


def _arrow(ax, start, end, color="#3a4a5a"):
    arrow = FancyArrowPatch(
        start,
        end,
        arrowstyle="-|>",
        mutation_scale=18,
        linewidth=2,
        color=color,
        connectionstyle="arc3,rad=0.0",
    )
    ax.add_patch(arrow)


def build_architecture_diagram(output_path: Path = OUTPUT_PATH) -> Path:
    fig, ax = plt.subplots(figsize=(20, 10), dpi=220)
    fig.patch.set_facecolor("white")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")

    fig.suptitle(
        "qmodel_compilation Architecture",
        fontsize=24,
        fontweight="bold",
        color="#16202a",
        y=0.98,
    )
    ax.text(
        0.5,
        0.94,
        "SQL-backed data loading → reusable analysis factory → concrete strategies → presentation outputs",
        ha="center",
        va="center",
        fontsize=12,
        color="#4d5b6a",
    )

    # Layer backgrounds
    layers = [
        (0.03, 0.10, 0.18, 0.78, "#f7f9fc", "Data Layer"),
        (0.23, 0.10, 0.22, 0.78, "#eef6ff", "Entry Points"),
        (0.47, 0.10, 0.18, 0.78, "#f4f0ff", "Factory / Base API"),
        (0.67, 0.10, 0.19, 0.78, "#eefaf4", "Analysis Strategies"),
        (0.88, 0.10, 0.09, 0.78, "#fff6ea", "Outputs"),
    ]
    for x, y, w, h, color, label in layers:
        ax.add_patch(
            FancyBboxPatch(
                (x, y),
                w,
                h,
                boxstyle="round,pad=0.015,rounding_size=0.02",
                linewidth=1.2,
                facecolor=color,
                edgecolor="#d3dbe6",
            )
        )
        ax.text(x + w / 2, y + h - 0.02, label, ha="center", va="top", fontsize=12, fontweight="bold", color="#304050")

    # Data layer
    _add_box(
        ax,
        (0.05, 0.63),
        0.14,
        0.18,
        "queries/*.sql",
        "Feature and target extraction for issues, PRs, defects, and commit metrics",
        "#dbeafe",
    )
    _add_box(
        ax,
        (0.05, 0.39),
        0.14,
        0.18,
        "DataCacheHandler",
        "Loads SQL, connects to MySQL, and caches results as CSV / Parquet / JSON / Pickle",
        "#bfdbfe",
    )
    _add_box(
        ax,
        (0.05, 0.15),
        0.14,
        0.18,
        "persistence/files",
        "Cached datasets used by the analysis scripts",
        "#e0f2fe",
    )

    # Entry points
    _add_box(
        ax,
        (0.26, 0.62),
        0.18,
        0.18,
        "clients/proven/*",
        "RQ1 / RQ2 / RQ3 runners such as Pearson, PCA, ANOVA, regression, and random forest",
        "#dbeafe",
    )
    _add_box(
        ax,
        (0.26, 0.36),
        0.18,
        0.18,
        "Context wrappers",
        "Simple adapters such as RfContext that invoke the chosen strategy",
        "#bfdbfe",
    )
    _add_box(
        ax,
        (0.26, 0.10),
        0.18,
        0.18,
        "README / demo assets",
        "Presentation figures and the Git commit graph demo",
        "#e0f2fe",
    )

    # Factory/base API
    _add_box(
        ax,
        (0.49, 0.56),
        0.14,
        0.22,
        "AnalysisFactory",
        "Maps strategy names to concrete analysis classes",
        "#e9ddff",
    )
    _add_box(
        ax,
        (0.49, 0.28),
        0.14,
        0.22,
        "AnalysisStrategy",
        "Shared interface for analyze() and visualization helpers",
        "#dccbff",
    )

    # Strategies
    _add_box(ax, (0.69, 0.73), 0.15, 0.12, "Pearson / Spearman", "Correlation analysis", "#d7f7e3")
    _add_box(ax, (0.69, 0.58), 0.15, 0.12, "PCA", "Dimensionality reduction", "#c7f0d8")
    _add_box(ax, (0.69, 0.43), 0.15, 0.12, "ANOVA", "Group significance testing", "#bfead1")
    _add_box(ax, (0.69, 0.28), 0.15, 0.12, "Linear Regression", "Coefficient estimation", "#b5e3c9")
    _add_box(ax, (0.69, 0.13), 0.15, 0.12, "Random Forest", "Feature importance and prediction fit", "#a9ddbf")
    _add_box(ax, (0.69, 0.01), 0.15, 0.10, "Elastic Net", "Regularized regression", "#9ed6b5")

    # Outputs
    _add_box(
        ax,
        (0.89, 0.68),
        0.07,
        0.14,
        "PNG figures",
        "Correlation, PCA, ANOVA, regression plots",
        "#ffe9c7",
    )
    _add_box(
        ax,
        (0.89, 0.48),
        0.07,
        0.14,
        "Reports",
        "Notebook-ready summary tables and metrics",
        "#ffdfad",
    )
    _add_box(
        ax,
        (0.89, 0.28),
        0.07,
        0.14,
        "Slides",
        "Assets for presentation decks",
        "#ffd796",
    )

    # Flow arrows
    _arrow(ax, (0.19, 0.72), (0.26, 0.71))
    _arrow(ax, (0.19, 0.48), (0.26, 0.48))
    _arrow(ax, (0.19, 0.24), (0.26, 0.28))
    _arrow(ax, (0.44, 0.71), (0.49, 0.67))
    _arrow(ax, (0.44, 0.48), (0.49, 0.38))
    _arrow(ax, (0.63, 0.67), (0.69, 0.79))
    _arrow(ax, (0.63, 0.67), (0.69, 0.64))
    _arrow(ax, (0.63, 0.67), (0.69, 0.49))
    _arrow(ax, (0.63, 0.38), (0.69, 0.34))
    _arrow(ax, (0.63, 0.38), (0.69, 0.19))
    _arrow(ax, (0.84, 0.79), (0.89, 0.75))
    _arrow(ax, (0.84, 0.64), (0.89, 0.55))
    _arrow(ax, (0.84, 0.49), (0.89, 0.35))
    _arrow(ax, (0.84, 0.34), (0.89, 0.35))
    _arrow(ax, (0.84, 0.19), (0.89, 0.35))

    ax.text(
        0.5,
        0.03,
        "Generated with matplotlib by demo/build_architecture_diagram.py",
        ha="center",
        va="center",
        fontsize=10,
        color="#6b7280",
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=220, bbox_inches="tight", facecolor=fig.get_facecolor())
    plt.close(fig)
    return output_path


if __name__ == "__main__":
    path = build_architecture_diagram()
    print(f"Architecture diagram written to {path}")

