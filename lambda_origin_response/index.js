'use strict'

const querystring = require('querystring')
const sharp = require('sharp')
const aws = require('aws-sdk')
const sizeof = require('sizeof')

const BUCKET = 'images.example.com'
const CACHE_SECONDS = 31536000
const MAX_WIDTH = 1200
const MAX_HEIGHT = 1200

exports.handler = async (event, context, callback) => {
  const { request, response } = event.Records[0].cf

  if (response.status === '304') {
    // response original
    callback(null, response)
    return
  }

  if (response.status !== '200') {
    // response not found
    response.status = '404'
    response.headers['content-type'] = [{ key: 'Content-Type', value: 'text/plain' }]
    response.body = `${request.uri} is not found.`
    callback(null, response)
    return
  }

  const query = querystring.parse(request.querystring)
  const options = {
    width: null,
    height: null
  }

  if (query.w) {
    const width = parseInt(query.w)
    if (!isNumber(width)) {
      responseError('Width must be numeric.')
      return
    }
    if (width <= 0 || MAX_WIDTH < width) {
      responseError(`Width must be greater than 0 and less than or equal to ${MAX_WIDTH}.`)
      return
    }
    options.width = width
  }

  if (query.h) {
    const height = parseInt(query.h)
    if (!isNumber(height)) {
      responseError('Height must be numeric.')
      return
    }
    if (height <= 0 || MAX_HEIGHT < height) {
      responseError(`Height must be greater than 0 and less than or equal to ${MAX_HEIGHT}.`)
      return
    }
    options.height = height
  }

  try {
    const s3 = new aws.S3()
    const s3Data = await s3.getObject({
        Bucket: BUCKET,
        Key: decodeURIComponent(request.uri).substr(1)
      }).promise()

    const sharpBody = sharp(s3Data.Body)

    if (options.width || options.height) {
      sharpBody.resize(options.width, options.height)
        .max()
    }

    const buffer = await sharpBody.toBuffer()

    // 1MB limit
    // https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/cloudfront-limits.html#limits-lambda-at-edge
    if (buffer.byteLength >= (1024 * 1000) - sizeof(response)) {
      callback(null, response)
      return
    }

    response.status = '200'
    response.body = buffer.toString('base64')
    response.bodyEncoding = 'base64'

    response.headers['cache-control'] = [{ key: 'Cache-Control', value: `public, max-age=${CACHE_SECONDS}` }]
    response.headers['expires'] = [{ key: 'Expires', value: (new Date(Date.now() + CACHE_SECONDS * 1000)).toUTCString() }]

    callback(null, response)
  } catch (e) {
    responseError('Internal Error', '500')
    console.log(e)
    return
  }

  function responseError(message, status = '403') {
    response.status = status
    response.headers['content-type'] = [{ key: 'Content-Type', value: 'text/plain' }]
    response.body = message
    callback(null, response)
  }
}

function isNumber(val) {
  return typeof val === 'number' && isFinite(val)
}
