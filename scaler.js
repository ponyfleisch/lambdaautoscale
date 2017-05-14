var AWS = require('aws-sdk');
var s3 = new AWS.S3();
var sharp = require('sharp');
var crypto = require('crypto');

const MAX_OUTPUT_DIMENSION = 6000;
const SECRET = process.env.SECRET;

var bucket = process.env.BUCKET;
var bucketUrl = process.env.BUCKET_URL;

// file name scheme: [hash]-[space]-[id]-[width]-[height].[extension]
// format: /s/[img]/200x200m.jpg?hash (m = max, c = crop)
// original: /o/[img].jpg

exports.scale = function (event, context) {
    function error(message) {
        return context.succeed({body: 'no: ' + message, statusCode: '400', headers: {}});
    }

    var parts = event.path.match(/\/s\/(.*)\/(\d+)x(\d+)([cm])\.([a-z]*)/);

    if (!parts) return error();

    var config = {
        name: parts[1],
        width: parseInt(parts[2], 10) || MAX_OUTPUT_DIMENSION,
        height: parseInt(parts[3], 10) || MAX_OUTPUT_DIMENSION,
        mode: parts[4],
        extension: parts[5],
        hash: Object.keys(event.queryStringParameters)[0]
    };

    // verify hash
    var hmac = crypto.createHmac('sha1', SECRET);
    hmac.update(event.path);
    var verifyHash = hmac.digest('base64');

    if (verifyHash != config.hash) {
        return error(config.hash);
    }

    var newObjectName = event.path.replace(/^\//g, '');

    var original = 'o/' + config.name + '.' + config.extension;

    s3.headObject({
        Bucket: bucket,
        Key: newObjectName
    }, function (err, data) {
        if (!err) {
            return context.succeed({body: '', statusCode: '302', headers: {'Location': bucketUrl + newObjectName}});
        } else {
            s3.getObject({
                Bucket: bucket,
                Key: original
            }, function (err, data) {
                if (err) {
                    return context.succeed({body: 'no: ' + original, statusCode: '404', headers: {}});
                } else {
                    var img = sharp(data.Body).resize(config.width, config.height);
                    if (config.mode != 'c') {
                        img.max();
                    }
                    img.toBuffer(function (err, buffer, info) {
                        if (err) {
                            return context.succeed({body: 'no.', statusCode: '500', headers: {}});
                        } else {
                            s3.putObject({
                                Bucket: bucket,
                                Key: newObjectName,
                                Body: buffer,
                                ContentType: data.ContentType,
                                CacheControl: data.CacheControl
                            }, function (err, data) {
                                if (err) {
                                    return context.succeed({body: 'no.', statusCode: '500', headers: {}});
                                } else {
                                    return context.succeed({
                                        body: '',
                                        statusCode: '302',
                                        headers: {'Location': bucketUrl + newObjectName + '?' + config.hash}
                                    });
                                }
                            });
                        }
                    });

                }
            });
        }
    });
}