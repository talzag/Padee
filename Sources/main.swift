import Kitura
import HeliumLogger

HeliumLogger.use()

let router = Router()
router.all("/", middleware: StaticFileServer())

let apiController = APIRouterController()
router.all("/api", middleware: apiController.router)

Kitura.addHTTPServer(onPort: 8000, with: router)
Kitura.run()
