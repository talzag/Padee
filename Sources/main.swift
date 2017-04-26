import Kitura
import HeliumLogger

HeliumLogger.use()

let router = Router()
router.all("/", middleware: StaticFileServer())

router.get("/api") { (request, response, next) in
    response.status(.OK).send("Response from Padee server API router")
    next()
}

Kitura.addHTTPServer(onPort: 8000, with: router)
Kitura.run()
