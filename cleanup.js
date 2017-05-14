var aws = require('aws-sdk');
var s3 = new aws.S3({apiVersion: '2006-03-01'});

var bucketName = process.env.BUCKET;

exports.cleanup = function (event, context, callback) {
    var bucket = event.Records[0].s3.bucket.name;
    var key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));

    var parts = key.match(/^o\/(.*)\.([a-z]*)$/);

    if (parts.length != 3 || parts[1] == '') {
        console.log('aborting');
        callback('nothing to clean up');
        return;
    }

    console.log(parts);

    s3.listObjectsV2({Bucket: bucketName, Prefix: 's/' + parts[1] + '/'}, function (err, data) {
        if (err) {
            return;
        } else {
            var promises = data.Contents.map(function (item) {
                console.log('deleting ' + item.Key);
                return new Promise(function (resolve, reject) {
                    s3.deleteObject({Bucket: bucketName, Key: item.Key}, function (err, data) {
                        if (err) {
                            console.err(err);
                        } else {
                            console.log('done');
                        }
                        resolve(data);
                    });
                });
            });

            Promise.all(promises).then(function () {
                callback(null);
            });
        }
    });
}