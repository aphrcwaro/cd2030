outlierDetectionUI <- function(id, i18n) {
  ns <- NS(id)

  tagList(
    contentHeader(ns('outlier_detection'), i18n$t('title_outlier'), i18n = i18n),
    contentBody(
      box(
        title = 'Outlier Options',
        status = 'success',
        solidHeader = TRUE,
        width = 12,
        fluidRow(
          column(3, adminLevelInputUI(ns('admin_level'), i18n)),
          column(3, selectizeInput(ns('indicator'),
                                   label = i18n$t('title_indicator'),
                                   choice = c('Select Indicator' = '', list_vaccines())))
        )
      ),
      tabBox(
        title = tags$span(icon('chart-line'), i18n$t('title_indicators_with_outlier')),
        width = 12,

        tabPanel(title = i18n$t('title_heat_map'), fluidRow(
          column(12, withSpinner(plotlyOutput(ns('district_outlier_heatmap')))),
          column(4, downloadButtonUI(ns('download_data')))
        )),

        tabPanel(title = i18n$t('title_vaccine_bar_graph'), fluidRow(
          column(12, plotCustomOutput(ns('vaccine_bar_graph')))
        )),

        tabPanel(title = i18n$t('title_region_bar_graph'), fluidRow(
          column(12, plotCustomOutput(ns('region_bar_graph')))
        ))
      ),
      box(
        title = i18n$t('title_district_outliers'),
        status = 'success',
        collapsible = TRUE,
        width = 6,
        fluidRow(
          column(3, selectizeInput(ns('year'), label = i18n$t('title_year'), choice = NULL)),
          column(3, offset = 6, downloadButtonUI(ns('download_outliers'))),
          column(12, withSpinner(reactableOutput(ns('district_outlier_summary'))))
        )
      ),
      box(
        title = i18n$t('title_district_trends'),
        status = 'success',
        collapsible = TRUE,
        width = 6,
        fluidRow(
          column(6, regionInputUI(ns('region'), i18n)),
          column(12, withSpinner(plotCustomOutput(ns('district_trend'))))
        )
      )
    )
  )
}

outlierDetectionServer <- function(id, cache, i18n) {
  stopifnot(is.reactive(cache))

  moduleServer(
    id = id,
    module = function(input, output, session) {

      admin_level <- adminLevelInputServer('admin_level')
      region <- regionInputServer('region', cache, admin_level, i18n)

      data <- reactive({
        req(cache())
        cache()$countdown_data
      })

      outlier_summary <- reactive({
        req(data(), admin_level())

        data() %>%
          calculate_outliers_summary(admin_level(), include_year = input$indicator != '')
      })

      outlier_districts <- reactive({
        req(data(), admin_level(), input$indicator, input$year)

        list_outlier_units(data(), input$indicator, admin_level()) %>%
          filter(year == as.integer(input$year))
      })

      observe({
        req(data())

        years <- data() %>%
          distinct(year) %>%
          arrange(desc(year)) %>%
          pull(year)

        updateSelectizeInput(session, 'year', choices = years)
      })

      output$district_outlier_summary <- renderReactable({
        req(outlier_districts())

        outlier_units <- outlier_districts() %>%
          filter(!!sym(paste0(input$indicator, '_outlier5std')) == 1) %>%
          select(-!!sym(paste0(input$indicator, '_outlier5std')))

        outlier_units %>%
          reactable(
            filterable = FALSE,
            minRows = 10,
            groupBy = 'adminlevel_1',
            columns = list(
              year = colDef(show = FALSE),
              month = colDef(
                aggregate = 'count',
                format = list(
                  aggregated = colFormat(suffix = ' month(s)')
                )
              )
            ),
            defaultColDef = colDef(
              cell = function(value) {
                if (!is.numeric(value)) {
                  return(value)
                }
                format(round(value), nsmall = 0)
              }
            )
          )
      })

      output$district_outlier_heatmap <- renderPlotly({
        req(outlier_summary())
        ggplotly(plot(outlier_summary(), 'heat_map', input$indicator))
      })

      output$region_bar_graph <- renderCustomPlot({
        req(outlier_summary(), input$indicator)
        plot(outlier_summary(), 'region', input$indicator)
      })

      output$vaccine_bar_graph <- renderCustomPlot({
        req(outlier_summary())
        plot(outlier_summary(), 'vaccine', input$indicator)
      })

      output$district_trend <- renderCustomPlot({
        req(outlier_districts(), region())
        plot(outlier_districts(), region())
      })

      downloadExcel(
        id = 'download_data',
        filename = reactive('checks_outlier_detection'),
        data = data,
        i18n = i18n,
        excel_write_function = function(wb) {
          completeness_rate <- data() %>% calculate_outliers_summary()
          district_completeness_rate <- data() %>% calculate_district_outlier_summary()

          sheet_name_1 <- i18n$t('title_outliers')
          addWorksheet(wb, sheet_name_1)
          writeData(wb, sheet = sheet_name_1, x = i18n$t('table_outliers'), startCol = 1, startRow = 1)
          writeData(wb, sheet = sheet_name_1, x = completeness_rate, startCol = 1, startRow = 3)

          # Check if sheet exists; if not, add it
          sheet_name_2 <- i18n$t('sheet_district_outliers')
          addWorksheet(wb, sheet_name_2)
          writeData(wb, sheet = sheet_name_2, x = i18n$t('table_district_outliers'), startRow = 1, startCol = 1)
          writeData(wb, sheet = sheet_name_2, x = district_completeness_rate, startCol = 1, startRow = 3)
        }
      )

      downloadExcel(
        id = 'download_outliers',
        filename = reactive(paste0('checks_outlier_districts_', input$indicator, '_', input$year)),
        data = outlier_districts,
        i18n = i18n,
        excel_write_function = function(wb) {
          district_outliers_sum <- outlier_districts()

          sheet_name_1 <- i18n$t('title_district_extreme_outlier')
          addWorksheet(wb, sheet_name_1)
          writeData(wb, sheet = sheet_name_1, x = str_glue(i18n$t('title_district_extreme_outlier_gen')), startCol = 1, startRow = 1)
          writeData(wb, sheet = sheet_name_1, x = district_outliers_sum, startCol = 1, startRow = 3)
        },
        label = 'btn_download_outlier'
      )

      contentHeaderServer(
        'outlier_detection',
        cache = cache,
        objects = pageObjectsConfig(input),
        md_title = i18n$t('title_outlier'),
        md_file = 'quality_checks_outlier_detection.md',
        i18n = i18n
      )
    }
  )
}
