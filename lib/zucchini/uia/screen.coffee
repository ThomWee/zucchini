class Screen
  takeScreenshot: (screenshotName) ->
    $.delay 0.5
    orientation = switch app.interfaceOrientation()
      when 0 then 'Unknown'
      when 1 then 'Portrait'
      when 2 then 'PortraitUpsideDown'
      when 3 then 'LandscapeLeft'
      when 4 then 'LandscapeRight'
      when 5 then 'FaceUp'
      when 6 then 'FaceDown'
    $.log "Screenshot of screen '#{@name}' taken with orientation '#{orientation}'"
    target.captureScreenWithName(screenshotName)

  element: (name) ->
    finder = @elements[name] || -> $('#' + name)

    unless el = wait finder
      raise "Element '#{name}' was not found on '#{@name}'"
    el

  constructor: (@name) ->

  elements: {}
  actions:
    'Take a screenshot$': -> @takeScreenshot(@name)

    'Take a screenshot named "([^"]*)"$': (name) -> @takeScreenshot(name)

    'Show elements' : -> view.logElementTree()

    'Show elements for "([^"]*)"$': (name) -> @element(name).logElementTree()

    'Tap "([^"]*)"$': (name) -> @element(name).tap()

    'Confirm "([^"]*)"$': (element) -> @actions['Tap "([^"]*)"$'].bind(this)(element)

    'Wait for "([^"]*)" second[s]*$': (seconds) -> target.delay(seconds)

    'Type "([^"]*)" in the "([^"]*)" field$': (text, name) ->
      $(@element(name)).input(text)

    'Clear the "([^"]*)" field$': (name) -> @element(name).setValue ''

    'Cancel the alert$' : ->
      alert = app.alert()
      raise "No alert found to dismiss on screen '#{@name}'" unless alert.isValid()
      alert.cancelButton().tap()

    'Confirm the alert$' : ->
      alert = app.alert()
      raise "No alert found to dismiss on screen '#{@name}'" unless alert.isValid()
      alert.defaultButton().tap()

    'Select the date "([^"]*)"$' : (dateString) ->
      datePicker = view.pickers()[0]
      raise "No date picker available to enter the date #{dateString}" unless datePicker.isValid() and datePicker.isVisible()
      dateParts = dateString.match(/^(\d{2}) (\D*) (\d{4})$/)
      raise "Date is in the wrong format. Need DD Month YYYY. Got #{dateString}" unless dateParts?
      # Set Day
      view.pickers()[0].wheels()[0].selectValue(dateParts[1])
      # Set Month
      counter = 0
      monthWheel = view.pickers()[0].wheels()[1]
      while monthWheel.value() != dateParts[2] and counter<12
          counter++
          monthWheel.tapWithOptions({tapOffset:{x:0.5, y:0.33}})
          target.delay(0.4)
      raise "Couldn't find the month #{dateParts[2]}" unless counter < 12
      # Set Year
      view.pickers()[0].wheels()[2].selectValue(dateParts[3])

    'Rotate device to "([^"]*)"$': (orientation) -> rotateTo(orientation)
