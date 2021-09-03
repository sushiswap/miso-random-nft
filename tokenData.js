const path = require('path');
const fs = require('fs');
const ipfsClient = require('ipfs-http-client')

const imageDirectory = 'img'
const jsonDirectory = 'metadata'
const ipfsURL = 'ipfs://ipfs/'

var ipfs = ipfsClient({ host: 'ipfs.infura.io', port: '5001', protocol: 'https' })

var addAndPinData = (data_) => {
    return new Promise((resolve, reject) => {
        const data = data_
        ipfs.add(data).then((result, err) => {
            if(err) reject(err)
            hash = result
            ipfs.pin.add(result.path).then((result, err) => {
                if(err) reject(err)
                resolve(hash.path)
            })
        })
    })
}
  
const readDirectory = (dir) => {
    return new Promise((resolve, reject) => {
        //joining path of directory 
        const directoryPath = path.join(__dirname, dir);
        //passsing directoryPath and callback function
        fs.readdir(directoryPath, function (err, files) {
            //handling error
            if (err) {
                reject('Unable to scan directory: ' + err)
            }
            resolve(files)
        });
    });

}

const readImage= (dir, file) => {
    return new Promise((resolve, reject) => {
        fs.readFile(dir + "/" + file, (err, image) => {
            if (err) {
                reject(err)
            }
            resolve(image)
        })
    });
}

const readJSON = (dir, file) => {
    return new Promise((resolve, reject) => {
        fs.readFile(dir + "/" + file, 'utf8', (err, jsonString) => {
            if (err) {
                reject(err)
            }
            resolve(JSON.parse(jsonString))
        })
    })
}

const getImageAndJson = async (imageDir, jsonDir, name) => {
    var promises = []
    promises.push(readImage(imageDir, name))
    promises.push(readJSON(jsonDir, name.split('.')[0] + '.json'))
    return Promise.all(promises)
}

const uploadImageAndJson = (image, json) => {
    return new Promise((resolve, reject) => {
        return addAndPinData(image).then((result, err) => {
            if(err) reject(err)
            var val = {}
            val.imageHash = result
            //update json
            json.image = ipfsURL + result
            return addAndPinData(JSON.stringify(json)).then((result, err) => {
                if(err) reject(err)
                val.metadataHash = result
                resolve(val)
            })
        })
    })
}

const rateLimitUpload = async (arr) => {
    responses = []
    for (let i = 0; i < arr.length; i++) {
        var response = await uploadImageAndJson(arr[i][0], arr[i][1]);
        responses.push(response)
    }
    return responses
}

readDirectory(imageDirectory).then((result) => {
    regex = new RegExp('.+((.gif)|(.jpg))');
    return result.filter(file => regex.exec(file))
}).then(files => {
    promises = []
    files.forEach(element => {
        promises.push(getImageAndJson(imageDirectory, jsonDirectory, element))
    });
    return Promise.all(promises)
})
.then(rateLimitUpload)
.then(result => {
    return fs.writeFile('tokenData.json', JSON.stringify(result), function (err) {
        if (err) return console.log(err);
    });
})