skip_on_cran()

library(WDI)


test_that("extra includes last updated", {
    x <- WDI(extra = TRUE)
    expect_true("lastupdated" %in% colnames(x))
})

# breaks on travis but works locally
test_that("WDIcache", {
    cache = WDIcache()
    expect_type(cache, "list")
    expect_gte(nrow(cache$series), 20000)
    # web cache = stored cache
    old <- WDIsearch("gdp.*capita.*constant")
    new <- WDIsearch("gdp.*capita.*constant", cache = cache)
    row.names(old) <- row.names(new) <- NULL
    expect_identical(old, new)
})

test_that("Bad indicator", {
    expect_warning(expect_s3_class(
        WDI(indicator = c("NY.GDP.PCAP.KD", "test"), country = "US", start = 1990, end = 1991),
        "data.frame"))
    expect_error(expect_null(
        WDI(indicator = c("bad", "test"), country = "US", start = 1990, end = 1990)))
})

test_that("Bad country", {
    expect_error(WDI(country = c("bad")))
    expect_warning(WDI(country = c("CA", "bad"), start = 1990, end = 1991))
})

test_that("Bad year", {
    expect_error(WDI(start = 1950))
    expect_error(WDI(start = 1991, end = 1990))
    expect_error(WDI(start = "1990M2", end = "1990M1"))
})

test_that("WDI", {
    # 1 country 1 indicator
    x <- WDI(country = "US", indicator = "NY.GDP.PCAP.KD", start = 1990, end = 1991)
    expect_s3_class(x, "data.frame")
    expect_equal(dim(x), c(2, 5))

    # 3 countries 1 indicator
    x <- WDI(
        country = c("CA", "MX", "US"),
        indicator = "NY.GDP.PCAP.KD",
        start = 1990, end = 1991)
    expect_s3_class(x, "data.frame")
    expect_equal(dim(x), c(6, 5))
    expect_equal(length(unique(x$iso2c)), 3)

    # multiple indicators
    ind <- c("NY.GDP.PCAP.KD", "NY.GDP.PCAP.KN", "NY.GDP.PCAP.PP.KD")
    x <- WDI(indicator = ind, start = 1990, end = 1991)
    expect_gte(nrow(x), 30)
    expect_equal(ncol(x), 7)

    # bad countries
    co <- c("BADCOUNTRY_one", "BADCOUNTRY_two", "CA", "MX", "US")
    x <- expect_warning(WDI(country = co, start = 1990, end = 1991))
    expect_equal(length(unique(x$iso2c)), 3)

    # bad indicator
    ind <- c("blah blah", "NY.GDP.PCAP.KD", "NY.GDP.PCAP.KN", "NY.GDP.PCAP.PP.KD", "NY.GDP.PCAP.PP.KD.87")
    x <- expect_warning(WDI(indicator = ind, start = 1990, end = 1991))
    expect_gte(nrow(x), 30)
    expect_equal(ncol(x), 7)
})

test_that("WDI(extra = TRUE)", {
    x <- WDI(
        country = "US", indicator = "NY.GDP.PCAP.KD",
        start = 1991, end = 1992, extra = TRUE)
    expect_s3_class(x, "data.frame")
    expect_equal(dim(x), c(2, 13))
})

test_that("extra = TRUE provides observation status", {
    x <- WDI(
        country = "US", indicator = "NY.GDP.PCAP.KD",
        start = 1991, end = 1992, extra = TRUE)
    expect_true("status" %in% names(x))
    expect_true(is.character(x$status))
})

test_that("behavior of start/end dates with latest", {
    expect_silent(
        WDI("all", "NY.GDP.PCAP.KD", start = NULL, end = NULL, latest = 5)
    )
    expect_silent(
        WDI("all", "NY.GDP.PCAP.KD", start = 1980, end = 2000)
    )
})

test_that("latest provides a dataframe", {
    y <- WDI("all", "NY.GDP.PCAP.KD", start = NULL, end = NULL, latest = 5)
    expect_s3_class(y, "data.frame")

    z <- WDI("all", "NY.GDP.PCAP.KD", latest = 5)
    expect_s3_class(z, "data.frame")
})

test_that("check that language doesn't change output format", {
    x <- suppressWarnings(
        WDI("all", "NY.GDP.PCAP.KD", language = "vi")
    )
    expect_s3_class(x, "data.frame")
})

test_that("default language is english", {
    x <- WDI("all", "NY.GDP.PCAP.KD")
    y <- WDI("all", "NY.GDP.PCAP.KD", language = "en")
    expect_true(identical(x, y))
})

test_that("NULL language is equivalent to english", {
    x <- WDI("all", "NY.GDP.PCAP.KD", language = NULL)
    y <- WDI("all", "NY.GDP.PCAP.KD", language = "en")
    expect_true(identical(x, y))
})

test_that("error if language not in list", {
    expect_error(
        WDI("all", "NY.GDP.PCAP.KD", language = "xyz")
    )
})

test_that("warning if language only supported partially", {
    expect_warning(
        WDI("all", "NY.GDP.PCAP.KD", language = "vi")
    )
})

test_that("languages_supported produces a list", {
    expect_type(
        languages_supported(),
        "list"
    )
})


test_that("rename on the fly", {
    ind <- c("women_private_sector" = "BI.PWK.PRVS.FE.ZS", "women_public_sector" = "BI.PWK.PUBS.FE.ZS")
    x <- WDI(country = "CA", indicator = ind)
    expect_identical(
        colnames(x),
        c("country", "iso2c", "iso3c", "year", "women_private_sector", "women_public_sector"))
})


test_that("fix iso codes wrongly attributed to iso2 or iso3, issue #54", {
    dat <- WDI(
        indicator = c("DT.ODA.ODAT.GN.ZS", "DT.ODA.ODAT.GD.ZS"),
        country = c("AO", "CG", "SA", "MZ"), start = 2000, end = 2020)

    expect_equal(unique(dat$iso3c), c("AGO", "COG", "MOZ", "SAU"))

    expect_equal(unique(dat$iso2c), c("AO", "CG", "MZ", "SA"))
})
