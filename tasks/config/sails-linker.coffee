###
Autoinsert script tags (or other filebased tags) in an html file.
###
module.exports = (grunt) ->
	grunt.config.set "sails-linker",
		devJs:
			options:
				startTag: "<!--SCRIPTS-->"
				endTag: "<!--SCRIPTS END-->"
				fileTmpl: "<script src=\"%s\"></script>"
				appRoot: ".tmp/public"

			files:
				".tmp/public/**/*.html": require("../pipeline").jsFilesToInject
				"views/**/*.html": require("../pipeline").jsFilesToInject
				"views/**/*.ejs": require("../pipeline").jsFilesToInject

		devJsRelative:
			options:
				startTag: "<!--SCRIPTS-->"
				endTag: "<!--SCRIPTS END-->"
				fileTmpl: "<script src=\"%s\"></script>"
				appRoot: ".tmp/public"
				relative: true

			files:
				".tmp/public/**/*.html": require("../pipeline").jsFilesToInject
				"views/**/*.html": require("../pipeline").jsFilesToInject
				"views/**/*.ejs": require("../pipeline").jsFilesToInject

		prodJs:
			options:
				startTag: "<!--SCRIPTS-->"
				endTag: "<!--SCRIPTS END-->"
				fileTmpl: "<script src=\"%s\"></script>"
				appRoot: ".tmp/public"

			files:
				".tmp/public/**/*.html": [".tmp/public/min/production.min.js"]
				"views/**/*.html": [".tmp/public/min/production.min.js"]
				"views/**/*.ejs": [".tmp/public/min/production.min.js"]

		prodJsRelative:
			options:
				startTag: "<!--SCRIPTS-->"
				endTag: "<!--SCRIPTS END-->"
				fileTmpl: "<script src=\"%s\"></script>"
				appRoot: ".tmp/public"
				relative: true

			files:
				".tmp/public/**/*.html": [".tmp/public/min/production.min.js"]
				"views/**/*.html": [".tmp/public/min/production.min.js"]
				"views/**/*.ejs": [".tmp/public/min/production.min.js"]

		devStyles:
			options:
				startTag: "<!--STYLES-->"
				endTag: "<!--STYLES END-->"
				fileTmpl: "<link rel=\"stylesheet\" href=\"%s\">"
				appRoot: ".tmp/public"

			files:
				".tmp/public/**/*.html": require("../pipeline").cssFilesToInject
				"views/**/*.html": require("../pipeline").cssFilesToInject
				"views/**/*.ejs": require("../pipeline").cssFilesToInject

		devStylesRelative:
			options:
				startTag: "<!--STYLES-->"
				endTag: "<!--STYLES END-->"
				fileTmpl: "<link rel=\"stylesheet\" href=\"%s\">"
				appRoot: ".tmp/public"
				relative: true

			files:
				".tmp/public/**/*.html": require("../pipeline").cssFilesToInject
				"views/**/*.html": require("../pipeline").cssFilesToInject
				"views/**/*.ejs": require("../pipeline").cssFilesToInject

		prodStyles:
			options:
				startTag: "<!--STYLES-->"
				endTag: "<!--STYLES END-->"
				fileTmpl: "<link rel=\"stylesheet\" href=\"%s\">"
				appRoot: ".tmp/public"

			files:
				".tmp/public/index.html": [".tmp/public/min/production.min.css"]
				"views/**/*.html": [".tmp/public/min/production.min.css"]
				"views/**/*.ejs": [".tmp/public/min/production.min.css"]

		prodStylesRelative:
			options:
				startTag: "<!--STYLES-->"
				endTag: "<!--STYLES END-->"
				fileTmpl: "<link rel=\"stylesheet\" href=\"%s\">"
				appRoot: ".tmp/public"
				relative: true

			files:
				".tmp/public/index.html": [".tmp/public/min/production.min.css"]
				"views/**/*.html": [".tmp/public/min/production.min.css"]
				"views/**/*.ejs": [".tmp/public/min/production.min.css"]


	# Bring in JST template object
		devTpl:
			options:
				startTag: "<!--TEMPLATES-->"
				endTag: "<!--TEMPLATES END-->"
				fileTmpl: "<script type=\"text/javascript\" src=\"%s\"></script>"
				appRoot: ".tmp/public"

			files:
				".tmp/public/index.html": [".tmp/public/jst.js"]
				"views/**/*.html": [".tmp/public/jst.js"]
				"views/**/*.ejs": [".tmp/public/jst.js"]

		devJsJade:
			options:
				startTag: "// SCRIPTS"
				endTag: "// SCRIPTS END"
				fileTmpl: "script(src=\"%s\")"
				appRoot: ".tmp/public"

			files:
				"views/**/*.jade": require("../pipeline").jsFilesToInject

		devJsRelativeJade:
			options:
				startTag: "// SCRIPTS"
				endTag: "// SCRIPTS END"
				fileTmpl: "script(src=\"%s\")"
				appRoot: ".tmp/public"
				relative: true

			files:
				"views/**/*.jade": require("../pipeline").jsFilesToInject

		prodJsJade:
			options:
				startTag: "// SCRIPTS"
				endTag: "// SCRIPTS END"
				fileTmpl: "script(src=\"%s\")"
				appRoot: ".tmp/public"

			files:
				"views/**/*.jade": [".tmp/public/min/production.min.js"]

		prodJsRelativeJade:
			options:
				startTag: "// SCRIPTS"
				endTag: "// SCRIPTS END"
				fileTmpl: "script(src=\"%s\")"
				appRoot: ".tmp/public"
				relative: true

			files:
				"views/**/*.jade": [".tmp/public/min/production.min.js"]

		devStylesJade:
			options:
				startTag: "// STYLES"
				endTag: "// STYLES END"
				fileTmpl: "link(rel=\"stylesheet\", href=\"%s\")"
				appRoot: ".tmp/public"

			files:
				"views/**/*.jade": require("../pipeline").cssFilesToInject

		devStylesRelativeJade:
			options:
				startTag: "// STYLES"
				endTag: "// STYLES END"
				fileTmpl: "link(rel=\"stylesheet\", href=\"%s\")"
				appRoot: ".tmp/public"
				relative: true

			files:
				"views/**/*.jade": require("../pipeline").cssFilesToInject

		prodStylesJade:
			options:
				startTag: "// STYLES"
				endTag: "// STYLES END"
				fileTmpl: "link(rel=\"stylesheet\", href=\"%s\")"
				appRoot: ".tmp/public"

			files:
				"views/**/*.jade": [".tmp/public/min/production.min.css"]

		prodStylesRelativeJade:
			options:
				startTag: "// STYLES"
				endTag: "// STYLES END"
				fileTmpl: "link(rel=\"stylesheet\", href=\"%s\")"
				appRoot: ".tmp/public"
				relative: true

			files:
				"views/**/*.jade": [".tmp/public/min/production.min.css"]


	# Bring in JST template object
		devTplJade:
			options:
				startTag: "// TEMPLATES"
				endTag: "// TEMPLATES END"
				fileTmpl: "script(type=\"text/javascript\", src=\"%s\")"
				appRoot: ".tmp/public"

			files:
				"views/**/*.jade": [".tmp/public/jst.js"]

	# Jasmine Tests
		testJs:
			options:
				startTag: "<!--TESTS-->"
				endTag: "<!--TESTS END-->"
				fileTmpl: "<script src=\"%s\"></script>"
				appRoot: ".tmp/public"

			files:
				".tmp/public/**/*.html": require("../pipeline").jsTestFilesToInject
				"views/**/*.html": require("../pipeline").jsTestFilesToInject
				"views/**/*.ejs": require("../pipeline").jsTestFilesToInject

		testStyles:
			options:
				startTag: "<!--TEST STYLES-->"
				endTag: "<!--TEST STYLES END-->"
				fileTmpl: "<link rel=\"stylesheet\" href=\"%s\">"
				appRoot: ".tmp/public"

			files:
				".tmp/public/**/*.html": require("../pipeline").cssTestStylesToInject
				"views/**/*.html": require("../pipeline").cssTestStylesToInject
				"views/**/*.ejs": require("../pipeline").cssTestStylesToInject

	grunt.loadNpmTasks "grunt-sails-linker"