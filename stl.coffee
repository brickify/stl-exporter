if typeof window isnt 'undefined'
	saveAs = require 'filesaver.js'


toAsciiStl = (model, options = {}) ->
	options.beautify ?= false

	{faceNormals, indices, positions, originalFileName} = model

	stringifyFaceNormal = (i) ->
		faceNormals[i] + ' ' +
			faceNormals[i + 1] + ' ' +
			faceNormals[i + 2]

	stringifyVector = (i) ->
		positions[(i * 3)] + ' ' +
			positions[(i * 3) + 1] + ' ' +
			positions[(i * 3) + 2]


	stl = "solid #{originalFileName}\n"

	if options.beautify
		for i in [0...indices.length] by 3
			stl +=
				"facet normal #{stringifyFaceNormal(i)}\n" +
					'\touter loop\n' +
					"\t\tvertex #{stringifyVector(indices[i])}\n" +
					"\t\tvertex #{stringifyVector(indices[i + 1])}\n" +
					"\t\tvertex #{stringifyVector(indices[i + 2])}\n" +
					'\tendloop\n' +
					'endfacet\n'
	else
		for i in [0...indices.length] by 3
			stl +=
				"facet normal #{stringifyFaceNormal(i)}\n" +
					'outer loop\n' +
					"vertex #{stringifyVector(indices[i])}\n" +
					"vertex #{stringifyVector(indices[i + 1])}\n" +
					"vertex #{stringifyVector(indices[i + 2])}\n" +
					'endloop\n' +
					'endfacet\n'

	stl += "endsolid #{originalFileName}\n"

	return stl


toBinaryStl = (model) ->
	{faceNormals, indices, positions} = model

	# Length in byte
	headerLength = 80 # 80 * uint8
	facetsCounterLength = 4 # 1 * uint32
	vectorLength = 12 # 3 * float32
	attributeByteCountLength = 2 # 1 * uint16
	facetLength = (vectorLength * 4 + attributeByteCountLength)
	contentLength = (indices.length / 3) * facetLength
	bufferLength = headerLength + facetsCounterLength + contentLength

	buffer = new ArrayBuffer(bufferLength)
	dataView = new DataView(buffer, headerLength)
	le = true # little-endian

	dataView.setUint32(0, (indices.length / 3), le)
	offset = facetsCounterLength

	for i in [0...indices.length] by 3
		# Normal
		dataView.setFloat32(offset, faceNormals[i], le)
		dataView.setFloat32(offset += 4, faceNormals[i + 1], le)
		dataView.setFloat32(offset += 4, faceNormals[i + 2], le)

		# X,Y,Z-Vector
		for a in [0..2]
			dataView.setFloat32(
				offset += 4, positions[indices[i + a] * 3], le
			)
			dataView.setFloat32(
				offset += 4, positions[indices[i + a] * 3 + 1], le
			)
			dataView.setFloat32(
				offset += 4, positions[indices[i + a] * 3 + 2], le
			)

		# Attribute Byte Count
		dataView.setUint16(offset += 4, 0, le)
		offset += 2

	return buffer


saveAsBinaryStl = (model) =>
	blob = new Blob [toBinaryStl(model)]

	saveAs blob, model.fileName


saveAsAsciiStl = (model) =>
	blob = new Blob [toAsciiStl(model)], {type: 'text/plain;charset=utf-8'}

	saveAs blob, model.fileName


module.exports =
	toAsciiStl: toAsciiStl
	toBinaryStl: toBinaryStl
	saveAsBinaryStl: saveAsBinaryStl
	saveAsAsciiStl: saveAsAsciiStl
