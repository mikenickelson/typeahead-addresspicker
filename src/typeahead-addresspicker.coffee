(($) ->
  class @AddressPickerResult
    constructor: (@placeResult) ->
      @latitude = @placeResult.geometry.location.lat()
      @longitude = @placeResult.geometry.location.lng()

    addressTypes: ->
      types = []
      for component in @addressComponents()
        for type in component.types
          types.push(type) if types.indexOf(type) == -1
      types

    addressComponents: ->
      @placeResult.address_components || []

    address: ->
      @placeResult.formatted_address

    nameForType: (type, shortName = false) ->
      for component in @addressComponents()
        return (if shortName then component.short_name else component.long_name) if component.types.indexOf(type) != -1
      null

    lat: ->
      @latitude

    lng: ->
      @longitude

    setLatLng: (@latitude, @longitude) ->

  class @AddressPicker extends Bloodhound
    constructor: (options = {})->
      @options = $.extend
        local: []
        datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace(d.num)
        queryTokenizer: Bloodhound.tokenizers.whitespace
        autocompleteService: {types: ["geocode"]}
        zoomForLocation: 16
        reverseGeocoding: false
      , options
      super(@options)
      
      @lastResult = null

      # Create a PlacesService on a fake DOM element
      @placeService = new google.maps.places.PlacesService(document.createElement('div'))
      @initService()

    # Binds typeahead:selected and typeahead:cursorchanged event to @updateMap
    bindDefaultTypeaheadEvent: (typeahead) ->
      typeahead.bind("typeahead:selected", @updateMap)
      typeahead.bind("typeahead:cursorchanged", @updateMap)

    unbindDefaultTypeaheadEvent: (typeahead) ->
      typeahead.unbind("typeahead:selected")
      typeahead.unbind("typeahead:cursorchanged")

    updateMap: (event, place) =>
      @placeService.getDetails place, (response) =>
        @lastResult = new AddressPickerResult(response)
        $(this).trigger('addresspicker:selected', @lastResult)

    initService: () ->
      self = @
      p1 = new google.maps.LatLng(37, 120);
      p2 = new google.maps.LatLng(40, 74);

      options =
        types: ['geocode']
        bounds: new google.maps.LatLngBounds(p1, p2)
        componentRestrictions:
          country: 'us'

      @service = new google.maps.places.AutocompleteService(@, options)
      return

    # Overrides Bloodhound#get  to send request to google maps autocomplete service
    get: (query, cb) ->      
      filteredPredictions = []

      @options.autocompleteService.input = query
      @service.getPlacePredictions @options.autocompleteService, (predictions) =>
        self = @
        
        for prediction in predictions
          if (/\b(United States|BC, Canada)\b/.test(prediction.description))
            prediction.description = prediction.description.replace(/, \b(United States|BC, Canada)\b/i, '')
            filteredPredictions.push(prediction)
            console.log(prediction.description)

        cb(filteredPredictions)
        $(self).trigger('addresspicker:predictions', [filteredPredictions])
      return

)(jQuery)
