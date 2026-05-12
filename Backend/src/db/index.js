import mongoose from "mongoose"
import {DB_NAME} from "../constants.js"

const connectDB = async ()=> {
    try {
        const baseUri = process.env.MONGODB_URI

        if (!baseUri) {
            throw new Error("MONGODB_URI is not set")
        }

        // If the URI already includes a database path, use it as-is.
        // Otherwise, append the configured DB_NAME.
        const hasDatabaseInUri = /\/[^/?]+(\?|$)/.test(baseUri)
        const mongoUri = hasDatabaseInUri
            ? baseUri
            : `${baseUri.replace(/\/+$/, "")}/${DB_NAME}`

        const connectionInstance = await mongoose.connect(mongoUri)
        console.log("DB connected... Host is ",connectionInstance.connection.host);        
    } catch (error) {
        console.log("DB connection failed. Error is ", error);
        process.exit(1)  
    }
}

export default connectDB 
