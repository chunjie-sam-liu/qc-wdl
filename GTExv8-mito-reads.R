# Metainfo ----------------------------------------------------------------

# @AUTHOR: Chun-Jie Liu
# @CONTACT: chunjie.sam.liu.at.gmail.com
# @DATE: Mon Dec  5 16:48:11 2022
# @DESCRIPTION: GTExv8-mito-reads.R

# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(patchwork)
library(rlang)

# src ---------------------------------------------------------------------


# header ------------------------------------------------------------------

future::plan(future::multisession, workers = 10)

# function ----------------------------------------------------------------


# load data ---------------------------------------------------------------
datapath <- "/home/liuc9/scratch/mitochondrial/GTExv8-reads-ratio/GTExv8-idxstats"

tissues <- tibble::tibble(
  tissuepath = list.dirs(path = datapath),
) %>% 
  dplyr::mutate(
    tissue = basename(tissuepath)
  ) %>% 
  dplyr::slice(-1)

# body --------------------------------------------------------------------


# Load data ---------------------------------------------------------------


tissues %>% 
  dplyr::mutate(
    mappedreads = purrr::map(
      .x = tissuepath,
      .f = function(.x) {
        tibble::tibble(
          idxstatsfilename = list.files(
            path = .x,
            pattern = ".idxstats"
          )
        ) %>% 
          dplyr::mutate(
            samplename = gsub(
              pattern = ".Aligned.sortedByCoord.out.patched.md.idxstats",
              replacement = "",
              x = idxstatsfilename
            )
          ) %>% 
          dplyr::mutate(
            mappedreads = furrr::future_map(
              .x = idxstatsfilename,
              .f = function(.f) {
                .ff <- file.path(.x, .f)
                .d <- readr::read_tsv(
                  file = .ff,
                  col_names = c("chrom", "reflength", "mappedreads", "unmappedreads")
                )
              }
            )
          ) %>% 
          dplyr::select(
            samplename,
            mappedreads
          )
        
      }
    )
  ) %>% 
  dplyr::select(-tissuepath) ->
  tissue_reads

readr::write_rds(
  x = tissue_reads,
  file = "/home/liuc9/scratch/mitochondrial/GTExv8-reads-ratio/tissue_reads.rds.gz"
)



# Ratio -------------------------------------------------------------------

tissue_reads %>% 
  dplyr::mutate(
    ratio = purrr::map(
      .x = mappedreads,
      .f = function(.x) {
        .x %>% 
          dplyr::mutate(
            ratio = purrr::map(
              .x = mappedreads,
              .f = function(.m) {
                .totalreads <- sum(c(.m$mappedreads, .m$unmappedreads))
                .m %>% 
                  dplyr::mutate(
                    ratio = (mappedreads / .totalreads) + (unmappedreads / .totalreads)
                  ) %>% 
                  dplyr::filter(!grepl(
                    pattern = "KI|GL|EBV", 
                    x = chrom
                  )) %>% 
                  dplyr::select(chrom, ratio) %>% 
                  dplyr::mutate(chrom = ifelse(chrom == "*", "unmapped", chrom)) ->
                  .mm
                tibble::tibble(
                  totalreads = .totalreads,
                  ratio = list(.mm)
                )
              }
            )
          ) %>% 
          dplyr::select(-mappedreads) %>% 
          tidyr::unnest(cols = ratio) %>% 
          tidyr::unnest(cols = ratio)
      }
    )
  ) %>% 
  dplyr::select(-mappedreads) %>% 
  tidyr::unnest(cols = ratio) ->
  tissue_reads_ratio


# Plot --------------------------------------------------------------------


tissue_reads_ratio %>% 
  dplyr::mutate(
    xchrom = ifelse(chrom %in% c("chrM", "unmapped"), chrom, "otherchrom")
  ) %>% 
  dplyr::mutate(
    xchrom = factor(
      x = xchrom,
      levels = c("unmapped", "otherchrom", "chrM")
    )
  ) ->
  tissue_reads_ratio_rename

tissue_reads_ratio_rename %>% 
  dplyr::filter(xchrom == "chrM") %>% 
  dplyr::group_by(tissue) %>% 
  dplyr::arrange(-ratio) %>% 
  dplyr::ungroup() ->
  samplerank

tissue_reads_ratio_rename %>% 
  dplyr::mutate(
    samplename = factor(
      x = samplename,
      levels = samplerank$samplename
    )
  ) ->
  tissue_reads_ratio_rename_forplot

color_gtexv8_tissues <- yaml::read_yaml(file = "/home/liuc9/github/sqtl/colors/color_gtexv8_tissue.yaml") %>% 
  tibble::enframe() %>% 
  tidyr::spread(key = name, value = value) %>% 
  tidyr::unnest()

tissue_reads_ratio_rename_forplot %>% 
  dplyr::select(tissue, samplename) %>% 
  dplyr::mutate(
    tissue = factor(
      x = tissue,
      levels = color_gtexv8_tissues$tissue
    )
  ) ->
  forp1 


forp1 %>% 
  ggplot(aes(x = samplename, y = 1, fill = tissue)) +
  geom_col(width = 1, show.legend = FALSE) +
  scale_fill_manual(
    values = color_gtexv8_tissues$color_hex
  ) +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank()
  ) ->
  p1;p1

tissue_reads_ratio_rename_forplot %>% 
  ggplot(aes(
    x = samplename,
    y = ratio,
    fill = xchrom
  )) +
  geom_col(width = 1) +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.005)),
    breaks = seq(0, 1, 0.1)
  ) +
  scale_fill_manual(
    values = ggsci::pal_aaas()(3)[c(3, 1, 2)],
    name = "Mapping",
    label = c("Unmapped", "1-22,X,Y", "chrM")
  ) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    panel.grid = element_blank(),
    panel.background = element_rect(color = "black", fill = NA),
    legend.position = "top",
    axis.title.x = element_blank(),
    axis.title = element_text(size = 16, face = "bold"),
    axis.text.y = element_text(size = 10, color = "black")
  ) +
  labs(
    y = "Reads mapping ratio"
  ) ->
  p2;p2


# layout <- c(
#   area(t = 1, l = 1, b = 29, r = 30),
#   area(t = 30, l = 1, b = 30, r = 30)
# )
# 
# p2/p1 + plot_layout(
#   design = layout,
# )

# cowplot::plot_grid(
#   plotlist = list(p2, p1),
#   align = 'v',
#   ncol = 1,
#   rel_heights = c(1, 0.05)
# )


p <- p2 / plot_spacer() / p1 + plot_layout(
  heights = c(40, -1.15, 1)
)

ggsave(
  filename = "GTExv8-RNAseq-mito-reads-distribution.pdf",
  plot = p,
  device = "pdf",
  path = "/home/liuc9/scratch/mitochondrial/GTExv8-reads-ratio",
  width = 15,
  height = 8
)


# dot plot ----------------------------------------------------------------


tissue_reads_ratio_rename %>% 
  dplyr::filter(xchrom == "chrM") %>% 
  dplyr::mutate(tissue = factor(
    x = tissue, 
    levels = color_gtexv8_tissues$tissue
  )) %>% 
  dplyr::mutate(totalreads = totalreads / 10^8) ->
  tissue_reads_ratio_rename_dot

tissue_reads_ratio_rename_dot %>% 
  dplyr::mutate(tissue = as.character(tissue)) %>% 
  dplyr::group_by(tissue) %>% 
  dplyr::summarise(m = median(ratio)) %>% 
  dplyr::arrange(-m)  ->
  tissue_reads_ratio_rename_dot_tissue_rank


tissue_reads_ratio_rename_dot %>% 
  dplyr::mutate(tissue = factor(
    x = tissue,
    levels = tissue_reads_ratio_rename_dot_tissue_rank$tissue
  )) %>% 
  ggplot(aes(x = tissue, y = ratio, color = tissue)) +
  geom_boxplot(width = 0.7, outlier.colour = NA) +
  geom_jitter(alpha=0.5,size=0.5,width = 0.2) +
  geom_smooth(
    mapping = aes(
      x = as.numeric(tissue),
      y = m,
    ),
    data = tissue_reads_ratio_rename_dot_tissue_rank %>% 
      dplyr::mutate(tissue = factor(
        x = tissue, 
        levels = tissue_reads_ratio_rename_dot_tissue_rank$tissue
      )),
    method = "loess",
    se = FALSE,
    color = "red",
    show.legend = FALSE,
    size = 1,
    linetype = "dotted"
  ) +
  scale_color_manual(
    name = "Tissue",
    values = color_gtexv8_tissues %>%
      dplyr::slice(match(tissue_reads_ratio_rename_dot_tissue_rank$tissue, tissue)) %>%
      dplyr::pull(color_hex),
    guide = guide_legend(
      ncol = 3
    )
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0.01, 0.2)),
    breaks = seq(0, 1, 0.1)
  ) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    panel.grid = element_blank(),
    panel.background = element_rect(fill = NA, color = "black"),
    legend.position = c(0.7, 0.75),
    legend.background = element_blank(), # element_rect(color = "red"),
    legend.key = element_blank(),
    legend.key.size = unit(x = 16, units = "points"),
    legend.text = element_text(size = 10),
    legend.title = element_blank(),
    axis.title = element_text(size = 16, face = "bold"),
    axis.text.y = element_text(size = 10, color = "black")
  ) +
  labs(
    x = "Tissue",
    y = "Mitochondrial reads mapping ratio"
  ) ->
  mito_boxplot;mito_boxplot

ggsave(
  filename = "GTExv8-RNAseq-mito-reads-distribution-boxplot.pdf",
  plot = mito_boxplot,
  device = "pdf",
  path = "/home/liuc9/scratch/mitochondrial/GTExv8-reads-ratio",
  width = 15,
  height = 8
)




tissue_reads_ratio_rename_dot %>% 
  ggplot(aes(x = totalreads, y = ratio, color = tissue)) +
  geom_point() +
  scale_color_manual(
    name = NULL,
    values = color_gtexv8_tissues$color_hex,
    guide = guide_legend(
      ncol = 2
    )
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0.01, 0.2)),
    breaks = seq(0, 1, by = 0.1)
  ) +
  scale_x_continuous(
    expand = expansion(mult = c(0.03, 0.08)),
    breaks = seq(0, 10, by = 1)
  ) +
  theme(
    panel.grid = element_blank(),
    panel.background = element_rect(fill = NA, color = "black"),
    legend.background = element_blank(),
    legend.key = element_blank(),
    legend.key.size = unit(x = 16, units = "points"),
    legend.text = element_text(size = 10),
    legend.title = element_blank(),
    axis.title = element_text(size = 16),
    axis.text = element_text(size = 10, color = "black")
  ) +
  labs(
    x = latex2exp::TeX("Total mapping reads ($x 10^8$)"),
    y = "Mitochondrial reads mapping ratio"
  ) ->
  mito_dot

ggsave(
  filename = "GTExv8-RNAseq-mito-reads-distribution-dotplot.pdf",
  plot = mito_dot,
  device = "pdf",
  path = "/home/liuc9/scratch/mitochondrial/GTExv8-reads-ratio",
  width = 15,
  height = 8
)


# footer ------------------------------------------------------------------

future::plan(future::sequential)

# save image --------------------------------------------------------------

save.image(
  file = "/home/liuc9/scratch/mitochondrial/GTExv8-reads-ratio/GTExv8-mito-reads.rda"
)
